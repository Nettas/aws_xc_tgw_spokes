# ==============================================================================
# AWS EC2 Instance - F5XC CE Node
#   eth0 (device_index 0) -> SLO subnet (outside, EIP for internet)
#   eth1 (device_index 1) -> SLI subnet (inside, workload traffic)
#
# Cloud-init writes /etc/vpm/user_data with the site token (current F5XC
# format for not_managed SMSv2 deployments — not the legacy config.yaml form).
# ==============================================================================

data "aws_ssm_parameter" "ce_ami" {
  name = var.ce_ami_ssm_parameter
}

locals {
  ce_userdata = <<-USERDATA
    #cloud-config
    write_files:
      - path: /etc/vpm/user_data
        permissions: '0644'
        owner: root
        content: |
          token: ${volterra_token.site_token.id}
  USERDATA
}

resource "aws_network_interface" "slo" {
  subnet_id         = aws_subnet.outside.id
  security_groups   = [aws_security_group.slo_sg.id]
  source_dest_check = true

  tags = merge(var.site_labels, { Name = "${var.site_name}-eth0-slo" })
}

resource "aws_network_interface" "sli" {
  subnet_id         = aws_subnet.inside.id
  security_groups   = [aws_security_group.sli_sg.id]
  source_dest_check = false # CE forwards traffic not addressed to itself

  tags = merge(var.site_labels, { Name = "${var.site_name}-eth1-sli" })
}

resource "aws_instance" "ce_node" {
  ami               = data.aws_ssm_parameter.ce_ami.value
  instance_type     = var.aws_instance_type
  availability_zone = var.aws_az
  key_name          = var.ssh_key_name != "" ? var.ssh_key_name : null

  root_block_device {
    volume_size = var.aws_disk_size_gb
    volume_type = "gp3"
  }

  network_interface {
    network_interface_id = aws_network_interface.slo.id
    device_index          = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.sli.id
    device_index          = 1
  }

  user_data                   = local.ce_userdata
  user_data_replace_on_change = false # avoid re-registration on unrelated changes

  tags = merge(var.site_labels, {
    Name        = "${var.site_name}-node0"
    "f5xc-site" = var.site_name
  })

  lifecycle {
    ignore_changes = [user_data]
  }

  depends_on = [
    volterra_token.site_token,
    aws_network_interface.slo,
    aws_network_interface.sli,
  ]
}

# -- Elastic IP for SLO internet egress --
resource "aws_eip" "slo_eip" {
  count             = var.assign_eip_to_slo ? 1 : 0
  domain            = "vpc"
  network_interface = aws_network_interface.slo.id

  tags = merge(var.site_labels, { Name = "${var.site_name}-slo-eip" })

  depends_on = [aws_internet_gateway.igw]
}
