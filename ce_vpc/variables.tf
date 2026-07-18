# ==============================================================================
# F5 Distributed Cloud - AWS SMSv2 Customer Edge
# Single-Node Site | 2-NIC (SLO + SLI) | Single VPC | Single AZ
# ==============================================================================

variable "f5xc_api_url" {
  description = "F5XC tenant API URL, e.g. https://mytenant.console.ves.volterra.io/api"
  type        = string
}

variable "f5xc_api_p12_file" {
  description = "Path to the F5XC API P12 credential file"
  type        = string
  sensitive   = true
}

variable "f5xc_tenant" {
  description = "F5XC tenant name (subdomain of your console URL)"
  type        = string
}

variable "f5xc_namespace" {
  description = "F5XC namespace for the site object"
  type        = string
  default     = "system"
}

variable "aws_region" {
  description = "AWS region for the VPC and CE node"
  type        = string
  default     = "us-west-1"
}

variable "aws_az" {
  description = "AWS availability zone for the CE node"
  type        = string
  default     = "us-west-1a"
}

variable "aws_instance_type" {
  description = "EC2 instance type. F5 minimum recommended is m5.2xlarge (8 vCPU/32GB)."
  type        = string
  default     = "m5.2xlarge"
}

variable "aws_disk_size_gb" {
  description = "Root EBS volume size in GB (80 GB minimum per F5 docs)"
  type        = number
  default     = 80
}

variable "ce_ami_ssm_parameter" {
  description = "SSM parameter path resolving to the latest F5XC CE Marketplace AMI ID"
  type        = string
  default     = "/aws/service/marketplace/prod-wrwzhcymymama/latest"
}

variable "vpc_name" {
  description = "Name of the CE VPC"
  type        = string
  default     = "f5xc-ce-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the CE VPC"
  type        = string
  default     = "10.110.0.0/16"
}

variable "outside_subnet_cidr" {
  description = "SLO (outside) subnet CIDR"
  type        = string
  default     = "10.110.1.0/24"
}

variable "inside_subnet_cidr" {
  description = "SLI (inside) subnet CIDR"
  type        = string
  default     = "10.110.2.0/24"
}

variable "site_name" {
  description = "F5XC site name (lowercase alphanumeric + '-', no dots)"
  type        = string
  default     = "aws-ce-site1"
}

variable "aws_credentials_name" {
  description = "Name of the F5XC AWS Cloud Credentials object"
  type        = string
  default     = "aws-cloud-cred"
}

variable "ssh_key_name" {
  description = "Existing AWS EC2 key pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "management_cidr" {
  description = "CIDR allowed to SSH and reach the CE local UI (port 65500). Restrict in production."
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS before applying in production
}

variable "site_labels" {
  description = "Tags applied to the F5XC site object and AWS resources"
  type        = map(string)
  default = {
    environment = "production"
    managed-by  = "terraform"
  }
}

variable "assign_eip_to_slo" {
  description = "Attach an Elastic IP directly to the SLO interface for internet egress"
  type        = bool
  default     = true
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for the F5XC AWS cloud credential object"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key_b64" {
  description = "Base64-encoded AWS Secret Access Key for the F5XC AWS cloud credential object"
  type        = string
  sensitive   = true
}
