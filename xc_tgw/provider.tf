terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.28"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  api_cert     = var.api_p12_file != "" ? "" : var.api_cert
  api_key      = var.api_p12_file != "" ? "" : var.api_key
  url          = var.api_url
}