###############################################################################
# F5 XC Secure Mesh Site v2 — "not managed" (we deploy the CE EC2 ourselves)
###############################################################################

#--- Registration token --------------------------------------------------------

resource "volterra_token" "ce" {
  name      = "${var.xc_site_name}-token"
  namespace = var.xc_namespace
}

#--- Secure Mesh Site v2 -------------------------------------------------------

resource "volterra_securemesh_site_v2" "ce" {
  name      = var.xc_site_name
  namespace = var.xc_namespace

  # Single node — no HA cluster
  disable_ha = true

  # AWS — not managed (Terraform + manual EC2, not F5 cloud orchestration)
  aws {
    not_managed {
      node_list {
        hostname = var.xc_site_name
        type     = "Control"

        # SLO interface — outside, internet-facing (eth0 / device_index 0)
        interface_list {
          name        = "eth0"
          description = "CE SLO — internet egress for registration and RE tunnels"

          ethernet_interface {
            device = "eth0"
          }

          network_option {
            site_local_network = true
          }

          # DHCP on SLO (AWS assigns IP via DHCP to the ENI)
          dhcp_client = true
        }

        # SLI interface — inside, TGW-facing (eth1 / device_index 1)
        interface_list {
          name        = "eth1"
          description = "CE SLI — faces TGW attachment for BGP peering and VIP publication"

          ethernet_interface {
            device = "eth1"
          }

          network_option {
            site_local_inside_network = true
          }

          # DHCP on SLI as well (AWS assigns IP via DHCP to the ENI)
          dhcp_client = true
        }
      }
    }
  }

  # No forward proxy (we're not proxying outbound from spokes yet)
  no_forward_proxy = true

  # No network policy
  no_network_policy = true

  # Admin credentials — SSH key if provided
  dynamic "admin_user_credentials" {
    for_each = var.xc_ssh_key != "" ? [1] : []
    content {
      ssh_key = var.xc_ssh_key
    }
  }

  # Labels for site selection (useful later for origin pools / VIP config)
  labels = {
    "site-type" = "hub-ce"
    "region"    = "ca-central-1"
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

#--- Registration approval (auto-approve when CE phones home) ------------------

resource "volterra_registration_approval" "ce" {
  cluster_name = var.xc_site_name
  cluster_size = 1
  hostname     = var.xc_site_name
  wait_time    = 60
  retry        = 30

  latitude  = tonumber(var.site_latitude)
  longitude = tonumber(var.site_longitude)

  depends_on = [volterra_securemesh_site_v2.ce]
}

# NOTE: volterra_site_state is only for decommission/reregistration control.
# Site readiness polling is handled by volterra_registration_approval above
# (wait_time=60s, retry=30 → waits up to 30 minutes for the CE to register).
