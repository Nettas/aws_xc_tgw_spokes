###############################################################################
# F5 XC Customer Edge EC2 instance
###############################################################################

#--- AMI lookup — latest F5 XC CE image ----------------------------------------

data "aws_ami" "ce" {
  most_recent = true
  owners      = ["434481986642"] # Volterra / F5 Distributed Cloud

  filter {
    name   = "name"
    values = ["f5xc-ce-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#--- Security groups -----------------------------------------------------------

# SLO security group — internet-facing for registration + RE tunnels
resource "aws_security_group" "ce_slo" {
  name        = "ce-slo-sg"
  description = "CE SLO - outbound all, inbound ICMP, optional SSH"
  vpc_id      = aws_vpc.hub.id

  # Outbound — allow all (registration, RE tunnels, origin discovery)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  # Inbound ICMP for troubleshooting
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP for diagnostics"
  }

  tags = {
    Name  = "ce-slo-sg"
    Owner = var.owner_tag
  }
}

# Conditional SSH rule — only created when ssh_trusted_cidr is set
resource "aws_security_group_rule" "ce_slo_ssh" {
  count             = var.ssh_trusted_cidr != "" ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_trusted_cidr]
  security_group_id = aws_security_group.ce_slo.id
  description       = "SSH from trusted CIDR"
}

# SLI security group — TGW-facing for spoke traffic + BGP
resource "aws_security_group" "ce_sli" {
  name        = "ce-sli-sg"
  description = "CE SLI - spoke traffic, BGP, ICMP"
  vpc_id      = aws_vpc.hub.id

  # Outbound — allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  # Inbound from hub VPC (includes TGW subnet)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.hub_vpc_cidr]
    description = "All traffic from hub VPC"
  }

  # Inbound from spoke 1 CIDR via TGW
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.100.0.0/16"]
    description = "All traffic from spoke 1 (BU1) via TGW"
  }

  # Inbound from spoke 2 CIDR via TGW
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "All traffic from spoke 2 (BU2) via TGW"
  }

  # Inbound ICMP for troubleshooting
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP for diagnostics"
  }

  tags = {
    Name  = "ce-sli-sg"
    Owner = var.owner_tag
  }
}

#--- Network interfaces --------------------------------------------------------

# SLO ENI — outside interface, internet-facing
resource "aws_network_interface" "ce_slo" {
  subnet_id         = aws_subnet.hub_slo.id
  security_groups   = [aws_security_group.ce_slo.id]
  source_dest_check = false # CE is an NVA — must disable

  tags = {
    Name  = "ce-slo-eni"
    Owner = var.owner_tag
  }
}

# SLI ENI — inside interface, TGW-facing
resource "aws_network_interface" "ce_sli" {
  subnet_id         = aws_subnet.hub_sli.id
  security_groups   = [aws_security_group.ce_sli.id]
  source_dest_check = false # CE is an NVA — must disable

  tags = {
    Name  = "ce-sli-eni"
    Owner = var.owner_tag
  }
}

#--- Elastic IP for SLO (registration/internet egress) -------------------------

resource "aws_eip" "ce_slo" {
  domain = "vpc"

  tags = {
    Name  = "ce-slo-eip"
    Owner = var.owner_tag
  }
}

resource "aws_eip_association" "ce_slo" {
  allocation_id        = aws_eip.ce_slo.id
  network_interface_id = aws_network_interface.ce_slo.id
}

#--- CE EC2 instance -----------------------------------------------------------

resource "aws_instance" "ce" {
  ami           = data.aws_ami.ce.id
  instance_type = var.ce_instance_type
  key_name      = var.key_name

  # Primary interface = SLO (device_index 0)
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ce_slo.id
  }

  # Secondary interface = SLI (device_index 1)
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.ce_sli.id
  }

  root_block_device {
    volume_size           = var.ce_disk_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Cloud-init user data for CE registration
  user_data = jsonencode({
    Token       = var.xc_site_token
    ClusterName = var.xc_cluster_name
    Latitude    = "45.5"
    Longitude   = "-73.6"
  })

  tags = {
    Name  = "f5-xc-ce-${var.xc_cluster_name}"
    Owner = var.owner_tag
  }

  depends_on = [
    aws_eip_association.ce_slo,
    aws_internet_gateway.hub,
  ]
}
