###############################################################################
# Outputs — consumed by xc_external_connector/ and spoke routing
###############################################################################

output "tgw_id" {
  description = "Transit Gateway ID — used by spokes for routing"
  value       = aws_ec2_transit_gateway.main.id
}

output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = aws_vpc.hub.id
}

output "hub_sli_subnet_id" {
  description = "Hub SLI subnet ID"
  value       = aws_subnet.hub_sli.id
}

output "ce_sli_private_ip" {
  description = "CE SLI interface private IP — used as BGP peer address"
  value       = aws_network_interface.ce_sli.private_ip
}

output "ce_slo_public_ip" {
  description = "CE SLO public IP (EIP) — for SSH access / diagnostics"
  value       = aws_eip.ce_slo.public_ip
}

output "ce_instance_id" {
  description = "CE EC2 instance ID"
  value       = aws_instance.ce.id
}

output "hub_tgw_attachment_id" {
  description = "Hub VPC TGW attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}
