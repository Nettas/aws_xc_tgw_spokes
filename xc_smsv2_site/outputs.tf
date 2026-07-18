output "site_name" {
  description = "F5 XC SMSv2 site name — used by external connector and BGP"
  value       = volterra_securemesh_site_v2.ce.name
}

output "site_token" {
  description = "Site registration token — used in CE EC2 user_data"
  value       = volterra_token.ce.id
  sensitive   = true
}

output "cluster_name" {
  description = "CE cluster name (same as site name for single-node)"
  value       = var.xc_site_name
}
