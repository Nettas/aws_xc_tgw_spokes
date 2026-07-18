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

output "registration_token" {
  value     = volterra_token.site_token.id
  sensitive = true
}

output "f5xc_console_sites_url" {
  value = "https://${var.f5xc_tenant}.console.ves.volterra.io/web/workspaces/multi-cloud-network-connect/overview/sites"
}
