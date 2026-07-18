#--- F5 XC API auth ------------------------------------------------------------

variable "xc_api_p12_file" {
  description = "Path to the F5 XC API P12 certificate file"
  type        = string
}

variable "xc_api_url" {
  description = "F5 XC API URL (e.g. https://<tenant>.console.ves.volterra.io/api)"
  type        = string
}

#--- Site reference ------------------------------------------------------------

variable "xc_site_name" {
  description = "Name of the SMSv2 site (from xc_smsv2_site/ output)"
  type        = string
}

variable "xc_namespace" {
  description = "F5 XC namespace"
  type        = string
  default     = "system"
}

#--- BGP configuration ---------------------------------------------------------

variable "ce_bgp_asn" {
  description = "BGP ASN for the F5 XC CE site"
  type        = number
  default     = 64513
}

variable "tgw_bgp_asn" {
  description = "BGP ASN for the AWS Transit Gateway"
  type        = number
  default     = 64512
}

variable "tgw_bgp_peer_ip" {
  description = "TGW-side BGP peer IP address (from TGW attachment ENI in the hub SLI subnet)"
  type        = string
}
