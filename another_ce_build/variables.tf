variable "vpc_name" {
  type        = string
  description = "Name of the existing VPC to deploy resources in"
  default     = "pveys-smsv2-vpc"
}

variable "owner" {
  type        = string
  description = "Owner/creator of the AWS resources (used for tagging)"
  default     = "pveys"
}

variable "f5xc-ce-site-name" {
  type        = string
  description = "F5XC CE site/cluster name (will have random suffix appended)"
  default     = "pveys-smsv2-aws-tf-igw"
}

variable "aws-ssh-key" {
    description = "AWS ssh key for the AMI"
    type        = string
}

variable "aws-region" {
  type        = string
  description = "AWS region for F5XC CE deployment"
  default     = "eu-west-3"
}

variable "aws-f5xc-ami" {
  type        = string
  description = "F5XC CE AMI ID to use for deployment"
  default     = "ami-032a3669fe1532f76"
}

variable "aws-ec2-flavor" {
  type        = string
  description = "EC2 instance type (allowed: m5.2xlarge, m5.4xlarge)"
  default = "m5.2xlarge"

  validation {
    condition     = contains(["m5.2xlarge", "m5.4xlarge"], var.aws-ec2-flavor)
    error_message = "Invalid EC2 instance type. Allowed values are: m5.2xlarge or m5.4xlarge."
  }
}

variable "slo-private-ip" {
    description = "Private IP for SLO interface"
    type        = string
}

variable "sli-private-ip" {
    description = "Private IP for SLI interface"
    type        = string
}

variable "f5xc_api_url" {
  type        = string
  description = "F5XC tenant API URL"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Path to F5XC tenant API key (.p12 file)"
  sensitive   = true
}

variable "f5xc_sms_description" {
  type        = string
  description = "Description for the F5XC site"
  default     = "F5XC SMSv2 AWS site created with Terraform"
}

variable "f5xc_software_version" {
  type        = string
  description = "F5XC software version for the site (only specify if default_sw_version is false)"
  default     = null
}

variable "f5xc_default_sw_version" {
  type        = bool
  description = "Use default software version (true) or specify custom version (false). If true, volterra_software_version must not be specified"
  default     = true

  validation {
    condition     = can(var.f5xc_default_sw_version)
    error_message = "f5xc_default_sw_version must be a boolean value."
  }
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public subnet for SLO interface"
  default     = "pveys-smsv2-public-3a"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private subnet for SLI interface"
  default     = "pveys-smsv2-private-3a"
}