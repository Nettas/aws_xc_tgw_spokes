terraform {
  required_version = ">= 1.5.0"

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~> 0.12"
    }
  }
}

provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_url
}
