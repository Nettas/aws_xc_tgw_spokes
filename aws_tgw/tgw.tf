###############################################################################
# Transit Gateway — hub-and-spoke with spoke isolation
###############################################################################

resource "aws_ec2_transit_gateway" "main" {
  amazon_side_asn                 = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name  = "hub-tgw"
    Owner = var.owner_tag
  }
}

###############################################################################
# VPC attachments
###############################################################################

# Hub VPC attachment — uses the dedicated TGW subnet
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = [var.hub_tgw_subnet_id]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name  = "tgw-attach-hub"
    Owner = var.owner_tag
  }
}

# Spoke 1 (BU1) attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke1" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.spoke1_vpc_id
  subnet_ids         = [var.spoke1_private_subnet_id]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name  = "tgw-attach-spoke1-bu1"
    Owner = var.owner_tag
  }
}

# Spoke 2 (BU2) attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke2" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.spoke2_vpc_id
  subnet_ids         = [var.spoke2_private_subnet_id]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name  = "tgw-attach-spoke2-bu2"
    Owner = var.owner_tag
  }
}

###############################################################################
# TGW route tables — isolated: spoke1↔hub, spoke2↔hub, NO spoke↔spoke
###############################################################################

# Hub route table — sees routes from both spokes
resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name  = "tgw-rt-hub"
    Owner = var.owner_tag
  }
}

# Spoke 1 route table — sees routes from hub only
resource "aws_ec2_transit_gateway_route_table" "spoke1" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name  = "tgw-rt-spoke1"
    Owner = var.owner_tag
  }
}

# Spoke 2 route table — sees routes from hub only
resource "aws_ec2_transit_gateway_route_table" "spoke2" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name  = "tgw-rt-spoke2"
    Owner = var.owner_tag
  }
}

###############################################################################
# Route table associations — each attachment uses its own RT
###############################################################################

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke1.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke2.id
}

###############################################################################
# Route table propagations — this is where spoke isolation happens
#
# Hub RT receives propagation from BOTH spokes (hub can reach both)
# Spoke 1 RT receives propagation from hub ONLY (cannot reach spoke 2)
# Spoke 2 RT receives propagation from hub ONLY (cannot reach spoke 1)
###############################################################################

# Hub can reach spoke 1
resource "aws_ec2_transit_gateway_route_table_propagation" "hub_from_spoke1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Hub can reach spoke 2
resource "aws_ec2_transit_gateway_route_table_propagation" "hub_from_spoke2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Spoke 1 can reach hub
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke1_from_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke1.id
}

# Spoke 2 can reach hub
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke2_from_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke2.id
}

# NOTE: No spoke1↔spoke2 propagation — spokes are isolated from each other
