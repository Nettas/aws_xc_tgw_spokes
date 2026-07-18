#--- AWS credentials -----------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ca-central-1"
}

variable "aws_access_key" {
  description = "AWS programmatic access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS programmatic secret key"
  type        = string
  sensitive   = true
}

variable "aws_token" {
  description = "AWS session token (optional, for temporary credentials)"
  type        = string
  sensitive   = true
  default     = null
}

#--- Hub VPC -------------------------------------------------------------------

variable "hub_vpc_cidr" {
  description = "CIDR block for the hub VPC"
  type        = string
  default     = "10.200.0.0/24"
}

variable "hub_slo_subnet_cidr" {
  description = "CIDR for the CE SLO (outside) subnet — internet egress for registration"
  type        = string
  default     = "10.200.0.0/27"
}

variable "hub_sli_subnet_cidr" {
  description = "CIDR for the CE SLI (inside) subnet — faces TGW, BGP peering, VIP publication"
  type        = string
  default     = "10.200.0.32/27"
}

variable "hub_tgw_subnet_cidr" {
  description = "CIDR for the TGW attachment ENIs"
  type        = string
  default     = "10.200.0.64/28"
}

variable "hub_az" {
  description = "Availability zone for hub subnets"
  type        = string
  default     = "ca-central-1a"
}

#--- Transit Gateway -----------------------------------------------------------

variable "tgw_asn" {
  description = "BGP ASN for the AWS Transit Gateway"
  type        = number
  default     = 64512
}

#--- Spoke VPC references (passed from spoke_1/ and spoke_2/ outputs) ----------

variable "spoke1_vpc_id" {
  description = "VPC ID of spoke 1 (BU1)"
  type        = string
}

variable "spoke1_private_subnet_id" {
  description = "Private subnet ID of spoke 1 for TGW attachment"
  type        = string
}

variable "spoke2_vpc_id" {
  description = "VPC ID of spoke 2 (BU2)"
  type        = string
}

variable "spoke2_private_subnet_id" {
  description = "Private subnet ID of spoke 2 for TGW attachment"
  type        = string
}

#--- CE instance ---------------------------------------------------------------

variable "ce_instance_type" {
  description = "EC2 instance type for the F5 XC Customer Edge node"
  type        = string
  default     = "m5.2xlarge"
}

variable "ce_disk_size_gb" {
  description = "Root volume size in GB for the CE node"
  type        = number
  default     = 80
}

variable "xc_site_token" {
  description = "F5 XC site registration token (from xc_smsv2_site/ output)"
  type        = string
  sensitive   = true
}

variable "xc_cluster_name" {
  description = "F5 XC CE cluster/site name (must match the SMSv2 site name)"
  type        = string
}

variable "key_name" {
  description = "AWS SSH key pair name for the CE instance"
  type        = string
}

variable "ssh_trusted_cidr" {
  description = "CIDR allowed to SSH into the CE node (empty string = no SSH access)"
  type        = string
  default     = ""
}

variable "owner_tag" {
  description = "Owner tag value for all resources"
  type        = string
  default     = "s.iannetta@f5.com"
}
