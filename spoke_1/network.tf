###############################################################################
# Spoke 1 (BU1) — networking
###############################################################################

resource "aws_internet_gateway" "bu1-igw" {
  vpc_id = aws_vpc.bu1.id
  tags = {
    Name = "bu1-igw"
  }
}

# Public route table — public subnet → IGW
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.bu1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bu1-igw.id
  }

  tags = {
    Name = "bu1-public-2-igw"
  }
}

resource "aws_route_table_association" "prod-crta-public-sub" {
  subnet_id      = aws_subnet.public-vpc-bu1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

# Private route table — private subnet → hub via TGW
resource "aws_route_table" "prod-private-crt" {
  vpc_id = aws_vpc.bu1.id

  tags = {
    Name = "bu1-private-rt"
  }
}

# Route to hub VPC via TGW (only created when tgw_id is provided)
resource "aws_route" "private_to_hub_via_tgw" {
  count                  = var.tgw_id != "" ? 1 : 0
  route_table_id         = aws_route_table.prod-private-crt.id
  destination_cidr_block = var.hub_vpc_cidr
  transit_gateway_id     = var.tgw_id
}

resource "aws_route_table_association" "prod-crta-private-sub" {
  subnet_id      = aws_subnet.private-vpc-bu1.id
  route_table_id = aws_route_table.prod-private-crt.id
}
