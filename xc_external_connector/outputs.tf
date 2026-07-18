output "external_connector_name" {
  description = "Name of the external connector resource"
  value       = volterra_external_connector.tgw.name
}

output "bgp_name" {
  description = "Name of the BGP configuration resource"
  value       = volterra_bgp.tgw.name
}
