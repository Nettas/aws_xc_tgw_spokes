terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">=0.11.42"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "aws" {
  region                   = var.aws-region
  shared_config_files      = "<your aws config location>"
  shared_credentials_files = "<your aws config location>"
  profile                  = "default"
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}