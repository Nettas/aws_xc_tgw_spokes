###############################################################################
# AWS credentials
###############################################################################

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "ca-central-1"
}

###############################################################################
# Hub VPC inputs (from ce_vpc outputs)
###############################################################################

variable "hub_vpc_id" {
  type        = string
  description = "Hub VPC ID (from ce_vpc output)"
}

variable "hub_tgw_subnet_id" {
  type        = string
  description = "Hub TGW attachment subnet ID (from ce_vpc output)"
}

variable "hub_sli_subnet_id" {
  type        = string
  description = "Hub SLI subnet ID (from ce_vpc output)"
}

variable "ce_sli_eni_id" {
  type        = string
  description = "CE SLI ENI ID — default route target in TGW subnet (from ce_vpc output)"
}

###############################################################################
# Spoke inputs (from spoke_1 and spoke_2 outputs)
###############################################################################

variable "spoke1_vpc_id" {
  type        = string
  description = "Spoke 1 VPC ID"
}

variable "spoke1_private_subnet_id" {
  type        = string
  description = "Spoke 1 private subnet ID for TGW attachment"
}

variable "spoke1_cidr" {
  type        = string
  default     = "10.100.0.0/16"
  description = "Spoke 1 VPC CIDR — used for SLI route table"
}

variable "spoke2_vpc_id" {
  type        = string
  description = "Spoke 2 VPC ID"
}

variable "spoke2_private_subnet_id" {
  type        = string
  description = "Spoke 2 private subnet ID for TGW attachment"
}

variable "spoke2_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Spoke 2 VPC CIDR — used for SLI route table"
}

###############################################################################
# TGW settings
###############################################################################

variable "tgw_asn" {
  type    = number
  default = 64512
}

variable "owner_tag" {
  type    = string
  default = "s.iannetta@f5.com"
}
