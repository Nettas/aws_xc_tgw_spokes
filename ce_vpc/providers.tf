terraform {
  required_version = ">= 1.3.0"

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.49" # pinned — verify against your installed version
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Credentials via env vars (source .f5xc-env.sh first):
#   export VOLT_API_URL="https://<tenant>.console.ves.volterra.io/api"
#   export VOLT_API_P12_FILE="/path/to/api-creds.p12"
#   export VES_P12_PASSWORD="<p12-password>"
provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
  timeout      = "120s"
}

# AWS credentials via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars
provider "aws" {
  region = var.aws_region
}