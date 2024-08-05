variable "aws_region" {
  description = "REQUIRED: AWS Region to deploy the Customer Edge into"
  type        = string
}

variable "aws_access_key" {
  description = "REQUIRED: AWS programatic access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "REQUIRED: AWS programatic secret key"
  type        = string
  sensitive   = true
}

# variable "sitelatitude" {
#   description = "REQUIRED: Site Physical Location Latitude. See https://www.latlong.net/"
#   type        = string
# }
# variable "sitelongitude" {
#   description = "REQUIRED: Site Physical Location Longitude. See https://www.latlong.net/"
#   type        = string
# }
# variable "clustername" {
#   description = "REQUIRED: Customer Edge site cluster name."
#   type        = string
# }

# variable "vpc" {
#   type = string
# }

# variable "SecurityServiceInsideCIDRAZ1" {
#   type        = string
#   description = "Subnet for inside interface of F5XC CE virtual appliances"
#   default     = "10.0.10.0/24"
# }

# variable "SecurityServiceOutsideCIDRAZ1" {
#   type        = string
#   description = "Subnet for inside interface of F5XC CE virtual appliances"
#   default     = "10.0.110.0/24"
# }

# variable "SecurityServiceWorkloadCIDRAZ1" {
#   type        = string
#   description = "Subnet for inside interface of F5XC CE virtual appliances"
#   default     = "10.0.127.0/24"
# }

# variable "az1" {
#   description = "OPTIONAL: AWS availability zone to deploy first Customer Edge into"
#   type        = string
#   default     = ""
# }

# variable "az2" {
#   description = "OPTIONAL: AWS availability zone to deploy second Customer Edge into"
#   type        = string
#   default     = ""
# }

# variable "az3" {
#   description = "OPTIONAL: AWS availability zone to deploy third Customer Edge into"
#   type        = string
#   default     = ""
# }

# variable "natgtwy" {
#   description = "aws nat gateway"
#   type        = string
#   default     = ""
# }

# variable "instance" {
#   description = "aws ec2 instance"
#   type        = string
#   default     = "t3.xlarge"
# }

variable "name" {
  description = "site name"
  type        = string
  default     = "netta-nat"
}

variable "cred" {
  description = "REQUIRED: Volterra AWS credentials name"
  type        = string
}

variable "tenant" {
  description = "REQUIRED: XC tenant name"
  type        = string
}

variable "api_url" {}
variable "api_p12_file" {}
variable "api_cert" {}
variable "api_key" {}
variable "ssh_key" {
  description = "REQUIRED public key"
  type        = string
}
# variable "sec_group" {
#   description = "REQUIRED"
#   type        = string
# }