###############################################################################
# AWS credentials & region
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

variable "aws_az" {
  type    = string
  default = "ca-central-1a"
}

###############################################################################
# F5 XC credentials
###############################################################################

variable "f5xc_api_url" {
  type        = string
  description = "F5XC tenant API URL"
}

variable "f5xc_api_p12_file" {
  type        = string
  sensitive   = true
  description = "Path to F5XC API P12 certificate file"
}

###############################################################################
# VPC networking
###############################################################################

variable "vpc_name" {
  type    = string
  default = "f5xc-ce-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.110.0.0/16"
}

variable "outside_subnet_cidr" {
  type        = string
  default     = "10.110.1.0/24"
  description = "SLO subnet CIDR"
}

variable "inside_subnet_cidr" {
  type        = string
  default     = "10.110.2.0/24"
  description = "SLI subnet CIDR"
}

variable "tgw_subnet_cidr" {
  type        = string
  default     = "10.110.3.0/24"
  description = "TGW attachment subnet CIDR"
}

###############################################################################
# CE site
###############################################################################

variable "site_name" {
  type    = string
  default = "aws-ce-site1"
}

variable "aws_instance_type" {
  type    = string
  default = "m5.2xlarge"

  validation {
    condition     = contains(["m5.2xlarge", "m5.4xlarge"], var.aws_instance_type)
    error_message = "Allowed values: m5.2xlarge or m5.4xlarge."
  }
}

variable "aws_disk_size_gb" {
  type    = number
  default = 80
}

variable "ce_ami_ssm_parameter" {
  type        = string
  default     = "/aws/service/marketplace/prod-wrwzhcymymama/latest"
  description = "SSM parameter path for the latest F5 XC CE Marketplace AMI"
}

###############################################################################
# Access & tags
###############################################################################

variable "ssh_key_name" {
  type    = string
  default = ""
}

variable "management_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR for SSH/UI access — restrict in production"
}

variable "owner" {
  type    = string
  default = "s.iannetta@f5.com"
}

variable "assign_eip_to_slo" {
  type    = bool
  default = true
}
