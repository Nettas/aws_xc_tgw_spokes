#--- F5 XC API auth ------------------------------------------------------------

variable "xc_api_p12_file" {
  description = "Path to the F5 XC API P12 certificate file"
  type        = string
}

variable "xc_api_url" {
  description = "F5 XC API URL (e.g. https://<tenant>.console.ves.volterra.io/api)"
  type        = string
}

#--- Site configuration --------------------------------------------------------

variable "xc_site_name" {
  description = "Name for the F5 XC Secure Mesh Site v2"
  type        = string
  default     = "aws-hub-smsv2"
}

variable "xc_namespace" {
  description = "F5 XC namespace (system for site objects)"
  type        = string
  default     = "system"
}

variable "xc_slo_ip" {
  description = "Static IP for the CE SLO interface (or empty for DHCP)"
  type        = string
  default     = ""
}

variable "xc_sli_ip" {
  description = "Static IP for the CE SLI interface (CIDR notation, e.g. 10.200.0.33/27)"
  type        = string
  default     = ""
}

variable "xc_sli_gateway" {
  description = "Default gateway for the CE SLI interface"
  type        = string
  default     = ""
}

variable "xc_ssh_key" {
  description = "SSH public key for CE admin access (optional)"
  type        = string
  default     = ""
}

variable "site_latitude" {
  description = "Site physical location latitude"
  type        = string
  default     = "45.5"
}

variable "site_longitude" {
  description = "Site physical location longitude"
  type        = string
  default     = "-73.6"
}
