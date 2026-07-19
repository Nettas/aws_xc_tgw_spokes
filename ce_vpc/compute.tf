###############################################################################
# CE EC2 Instance — dual-homed (eth0=SLO, eth1=SLI)
###############################################################################

#--- AMI lookup ----------------------------------------------------------------

data "aws_ssm_parameter" "ce_ami" {
  name = var.ce_ami_ssm_parameter
}

#--- Network interfaces --------------------------------------------------------

resource "aws_network_interface" "slo" {
  subnet_id         = aws_subnet.outside.id
  security_groups   = [aws_security_group.slo_sg.id]
  source_dest_check = false

  tags = { Name = "${var.site_name}-eth0-slo", Owner = var.owner }
}

resource "aws_network_interface" "sli" {
  subnet_id         = aws_subnet.inside.id
  security_groups   = [aws_security_group.sli_sg.id]
  source_dest_check = false

  tags = { Name = "${var.site_name}-eth1-sli", Owner = var.owner }
}

#--- EIP for SLO ---------------------------------------------------------------

resource "aws_eip" "slo_eip" {
  count  = var.assign_eip_to_slo ? 1 : 0
  domain = "vpc"

  tags = { Name = "${var.site_name}-slo-eip", Owner = var.owner }
}

resource "aws_eip_association" "slo_eip" {
  count                = var.assign_eip_to_slo ? 1 : 0
  allocation_id        = aws_eip.slo_eip[0].id
  network_interface_id = aws_network_interface.slo.id
}

#--- CE instance ---------------------------------------------------------------

resource "aws_instance" "ce_node" {
  depends_on    = [aws_security_group.sli_sg]
  ami           = data.aws_ssm_parameter.ce_ami.value
  instance_type = var.aws_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.slo.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.sli.id
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.aws_disk_size_gb
  }

  user_data = data.cloudinit_config.ce_config.rendered

  tags = {
    Name                                               = var.site_name
    Owner                                              = var.owner
    "ves-io-site-name"                                 = var.site_name
    "kubernetes.io/cluster/${var.site_name}"            = "owned"
  }
}
