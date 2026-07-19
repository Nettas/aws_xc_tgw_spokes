###############################################################################
# Security Groups — SLO (internet-facing) and SLI (workload traffic)
###############################################################################

resource "aws_security_group" "slo_sg" {
  name        = "${var.site_name}-sg-SLO"
  description = "CE SLO - outbound all, inbound ICMP, optional SSH"
  vpc_id      = aws_vpc.vpc.id

  # CE needs outbound: TCP 443, UDP 4500, TCP/UDP 53, NTP 123
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Uncomment to enable SSH and ICMP for troubleshooting
  # ingress {
  #   description = "SSH from trusted"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.management_cidr]
  # }

  # ingress {
  #   description = "ICMP from trusted"
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmp"
  #   cidr_blocks = [var.management_cidr]
  # }

  tags = { Name = "${var.site_name}-sg-SLO", Owner = var.owner }
}

resource "aws_security_group" "sli_sg" {
  name        = "${var.site_name}-sg-SLI"
  description = "CE SLI - all traffic in/out for workload forwarding"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.site_name}-sg-SLI", Owner = var.owner }
}
