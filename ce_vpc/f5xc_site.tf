# ==============================================================================
# F5 Distributed Cloud - AWS Cloud Credentials
#
# ⚠️ Verify this block against your installed provider before apply:
#   terraform providers schema -json | jq \
#     '.provider_schemas."registry.terraform.io/volterraedge/volterra".resource_schemas.volterra_cloud_credentials'
# ==============================================================================
resource "volterra_cloud_credentials" "aws" {
  name        = var.aws_credentials_name
  namespace   = "system"
  description = "AWS credentials for F5XC CE deployment"

  aws_secret_key {
    access_key = var.aws_access_key_id

    secret_key {
      clear_secret_info {
        url = "string:///${var.aws_secret_access_key_b64}"
      }
    }
  }
}

# ==============================================================================
# Single-Node CE Site | 2-NIC (SLO + SLI)
#
# ⚠️ Verify `aws_az_name` against your installed schema:
#   terraform providers schema -json | jq \
#     '.provider_schemas."registry.terraform.io/volterraedge/volterra".resource_schemas.volterra_securemesh_site_v2'
# ==============================================================================
resource "volterra_securemesh_site_v2" "site" {
  name        = var.site_name
  namespace   = var.f5xc_namespace
  description = "F5XC CE Site - AWS ${var.aws_az} - 2-NIC"

  logs_streaming_disabled = true
  block_all_services      = false
  enable_ha               = false

  labels = merge(var.site_labels, {
    "ves.io/provider" = "ves-io-AWS"
    "site-az"         = var.aws_az
  })

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {
      node_list {
        aws_az_name = var.aws_az
        hostname    = "${var.site_name}-node0"

        interface_list {
          # -- Interface 0 - SLO (Site Local Outside) - eth0 --
          interfaces {
            description = "SLO - Site Local Outside"

            ethernet_interface {
              device = "eth0"
              mtu    = 1500

              dhcp_client {}
              site_local_outside_network {}

              is_primary       = true
              monitor_disabled = false
            }
          }

          # -- Interface 1 - SLI (Site Local Inside) - eth1 --
          interfaces {
            description = "SLI - Site Local Inside"

            ethernet_interface {
              device = "eth1"
              mtu    = 1500

              dhcp_client {}
              site_local_inside_network {}

              is_primary       = false
              monitor_disabled = false
            }
          }
        }
      }
    }
  }

  multiple_interface {}

  private_connectivity_disabled = true

  depends_on = [volterra_cloud_credentials.aws]
}

# ==============================================================================
# Registration Token (type = 1) — injected via cloud-init into /etc/vpm/user_data
# ==============================================================================
resource "volterra_token" "site_token" {
  name      = "${var.site_name}-token"
  namespace = var.f5xc_namespace
  type      = 1

  site_name = volterra_securemesh_site_v2.site.name

  depends_on = [volterra_securemesh_site_v2.site]
}
