###############################################################################
# Hub VPC routing — wired AFTER TGW is created
#
# SLI route table: spoke CIDRs → TGW (so CE can reach spoke workloads)
# TGW route table: default → CE SLI ENI (so spoke traffic hits the CE)
###############################################################################

#--- SLI subnet routes to spokes via TGW --------------------------------------

resource "aws_route_table" "hub_sli" {
  vpc_id = var.hub_vpc_id

  tags = {
    Name  = "hub-sli-rt"
    Owner = var.owner_tag
  }
}

resource "aws_route" "hub_sli_to_spoke1" {
  route_table_id         = aws_route_table.hub_sli.id
  destination_cidr_block = var.spoke1_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_sli_to_spoke2" {
  route_table_id         = aws_route_table.hub_sli.id
  destination_cidr_block = var.spoke2_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route_table_association" "hub_sli" {
  subnet_id      = var.hub_sli_subnet_id
  route_table_id = aws_route_table.hub_sli.id
}

#--- TGW subnet default route → CE SLI ENI ------------------------------------

resource "aws_route_table" "hub_tgw" {
  vpc_id = var.hub_vpc_id

  tags = {
    Name  = "hub-tgw-rt"
    Owner = var.owner_tag
  }
}

resource "aws_route" "hub_tgw_to_ce" {
  route_table_id         = aws_route_table.hub_tgw.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = var.ce_sli_eni_id
}

resource "aws_route_table_association" "hub_tgw" {
  subnet_id      = var.hub_tgw_subnet_id
  route_table_id = aws_route_table.hub_tgw.id
}
