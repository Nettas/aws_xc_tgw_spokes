###############################################################################
# Outputs — consumed by aws_tgw/ and for diagnostics
###############################################################################

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "site_name" {
  value = volterra_securemesh_site_v2.site.name
}

output "ce_instance_id" {
  value = aws_instance.ce_node.id
}

output "slo_private_ip" {
  value = aws_network_interface.slo.private_ip
}

output "slo_public_ip" {
  value = var.assign_eip_to_slo ? aws_eip.slo_eip[0].public_ip : null
}

output "sli_private_ip" {
  value = aws_network_interface.sli.private_ip
}

output "sli_eni_id" {
  description = "SLI ENI ID — used as route target in TGW subnet route table"
  value       = aws_network_interface.sli.id
}

output "sli_subnet_id" {
  description = "SLI subnet ID — for reference"
  value       = aws_subnet.inside.id
}

output "tgw_subnet_id" {
  description = "TGW attachment subnet ID — used by aws_tgw for hub attachment"
  value       = aws_subnet.tgw.id
}

output "registration_token" {
  value     = volterra_token.site_token.id
  sensitive = true
}
