variable "aws_region" {
  description = "REQUIRED: AWS Region to deploy the Customer Edge into"
  type        = string
  default = "us-east-2"
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

variable "aws_token" {
  description = "OPTIONAL: AWS programatic token"
  type        = string
  sensitive   = true
  default     = null
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
# variable "sitetoken" {
#   description = "REQUIRED: Distributed Cloud Customer Edge site registration token."
#   type        = string
#   sensitive   = true
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

variable "awsRegion" {
  type    = string
  default = "us-east-2"
}

variable "ami" {
  type    = string
  default = "ami-0ee4f2271a4df2d7d"
}

variable "az" {
  type    = string
  default = "us-east-2a"
}

variable "key_name" {
  type = string
  default = "netta-aws-east2-xc-account"
}