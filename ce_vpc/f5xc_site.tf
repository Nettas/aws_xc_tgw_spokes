###############################################################################
# F5 XC Secure Mesh Site v2 — "not managed" (CE deployed via Terraform)
#
# Proven pattern: empty not_managed {} — let the CE self-identify at
# registration time. Do NOT define node_list, hostname, type, or interfaces.
###############################################################################

resource "volterra_securemesh_site_v2" "site" {
  name                    = var.site_name
  namespace               = "system"
  description             = "F5XC SMSv2 CE - ${var.aws_region} - hub site"
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false

  labels = {
    "ves.io/provider" = "ves-io-AWS"
  }

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
  }

  software_settings {
    os {
      default_os_version = true
    }
    sw {
      default_sw_version = true
    }
  }
}

#--- Registration token --------------------------------------------------------

resource "volterra_token" "site_token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = "${var.site_name}-token"
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}

#--- Cloud-init user data ------------------------------------------------------

data "cloudinit_config" "ce_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      #cloud-config
      write_files = [
        {
          path        = "/etc/vpm/user_data"
          permissions = "0644"
          owner       = "root"
          content     = "token: ${volterra_token.site_token.id}"
        }
      ]
    })
  }
}
