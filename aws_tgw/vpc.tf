###############################################################################
# Hub VPC — hosts the F5 XC CE node and the TGW attachment
###############################################################################

resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "hub-vpc"
    Owner = var.owner_tag
  }
}

###############################################################################
# Internet Gateway — CE SLO needs outbound for registration + RE tunnels
###############################################################################

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name  = "hub-igw"
    Owner = var.owner_tag
  }
}

###############################################################################
# Subnets
###############################################################################

# CE SLO (outside) — internet-facing for registration and origin discovery
resource "aws_subnet" "hub_slo" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = var.hub_slo_subnet_cidr
  availability_zone       = var.hub_az
  map_public_ip_on_launch = false

  tags = {
    Name  = "hub-slo"
    Owner = var.owner_tag
  }
}

# CE SLI (inside) — faces TGW attachment, BGP peering, VIP publication
resource "aws_subnet" "hub_sli" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = var.hub_sli_subnet_cidr
  availability_zone       = var.hub_az
  map_public_ip_on_launch = false

  tags = {
    Name  = "hub-sli"
    Owner = var.owner_tag
  }
}

# TGW attachment ENIs — AWS places its ENIs here when attaching the hub VPC
resource "aws_subnet" "hub_tgw" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = var.hub_tgw_subnet_cidr
  availability_zone       = var.hub_az
  map_public_ip_on_launch = false

  tags = {
    Name  = "hub-tgw-attach"
    Owner = var.owner_tag
  }
}

###############################################################################
# Route tables
###############################################################################

# SLO route table — default route out to IGW for internet access
resource "aws_route_table" "hub_slo" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name  = "hub-slo-rt"
    Owner = var.owner_tag
  }
}

# SLI route table — spoke CIDRs via TGW
resource "aws_route_table" "hub_sli" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name  = "hub-sli-rt"
    Owner = var.owner_tag
  }
}

resource "aws_route" "hub_sli_to_spoke1" {
  route_table_id         = aws_route_table.hub_sli.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_sli_to_spoke2" {
  route_table_id         = aws_route_table.hub_sli.id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

# TGW subnet route table — traffic arriving from TGW destined for CE SLI
resource "aws_route_table" "hub_tgw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name  = "hub-tgw-rt"
    Owner = var.owner_tag
  }
}

# Return traffic from TGW subnet → CE SLI ENI (for spoke-to-hub flows)
resource "aws_route" "hub_tgw_to_ce" {
  route_table_id         = aws_route_table.hub_tgw.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.ce_sli.id
}

###############################################################################
# Route table associations
###############################################################################

resource "aws_route_table_association" "hub_slo" {
  subnet_id      = aws_subnet.hub_slo.id
  route_table_id = aws_route_table.hub_slo.id
}

resource "aws_route_table_association" "hub_sli" {
  subnet_id      = aws_subnet.hub_sli.id
  route_table_id = aws_route_table.hub_sli.id
}

resource "aws_route_table_association" "hub_tgw" {
  subnet_id      = aws_subnet.hub_tgw.id
  route_table_id = aws_route_table.hub_tgw.id
}
