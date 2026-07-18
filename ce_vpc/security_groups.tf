# ==============================================================================
# Security Groups — SLO (control-plane egress) and SLI (workload traffic)
# ==============================================================================

resource "aws_security_group" "slo_sg" {
  name        = "${var.vpc_name}-ce-slo-sg"
  description = "F5XC CE SLO interface - control-plane/tunnel traffic to Regional Edges"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description = "HTTPS control-plane to F5XC REs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "IPsec tunnel to F5XC REs"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP for troubleshooting"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.management_cidr]
  }

  ingress {
    description = "SSH management access - RESTRICT IN PRODUCTION"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  ingress {
    description = "F5XC CE local UI (port 65500) for troubleshooting"
    from_port   = 65500
    to_port     = 65500
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  tags = merge(var.site_labels, { Name = "${var.vpc_name}-ce-slo-sg" })
}

resource "aws_security_group" "sli_sg" {
  name        = "${var.vpc_name}-ce-sli-sg"
  description = "F5XC CE SLI interface - workload forwarding traffic"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description = "All egress for workload forwarding"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Workload traffic into CE SLI"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.inside_subnet_cidr]
  }

  ingress {
    description = "ICMP for troubleshooting"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.management_cidr]
  }

  tags = merge(var.site_labels, { Name = "${var.vpc_name}-ce-sli-sg" })
}
