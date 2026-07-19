###############################################################################
# Outputs — tgw_id fed back to spokes to enable their conditional TGW routes
###############################################################################

output "tgw_id" {
  description = "Transit Gateway ID — pass to spoke_1/spoke_2 as tgw_id variable"
  value       = aws_ec2_transit_gateway.main.id
}

output "hub_tgw_attachment_id" {
  description = "Hub VPC TGW attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}
