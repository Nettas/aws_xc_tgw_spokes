###############################################################################
# External Connector — CE ↔ TGW direct (L2 adjacent) connection
###############################################################################

resource "volterra_external_connector" "tgw" {
  name      = "${var.xc_site_name}-tgw-connector"
  namespace = var.xc_namespace

  description = "Direct connection from CE SLI to AWS TGW (same VPC, L2 adjacent)"

  # Reference to the SMSv2 site
  ce_site_reference {
    name      = var.xc_site_name
    namespace = var.xc_namespace
  }

  # Direct connection — CE SLI and TGW attachment ENIs are in the same VPC,
  # reachable at L2/L3 without tunneling
  direct_connection {}
}

###############################################################################
# BGP — CE (ASN 64513) peers with TGW (ASN 64512)
###############################################################################

resource "volterra_bgp" "tgw" {
  name      = "${var.xc_site_name}-tgw-bgp"
  namespace = var.xc_namespace

  description = "BGP peering between CE (ASN ${var.ce_bgp_asn}) and AWS TGW (ASN ${var.tgw_bgp_asn})"

  # CE-side BGP parameters
  bgp_parameters {
    asn        = var.ce_bgp_asn
    local_address = true
  }

  # TGW peer
  peers {
    metadata {
      name        = "tgw-peer"
      description = "AWS Transit Gateway BGP peer"
    }

    external {
      asn               = var.tgw_bgp_asn
      address           = var.tgw_bgp_peer_ip
      external_connector = true

      # Accept default routes from TGW (not needed yet, but ready for it)
      family_inet {
        enable {}
      }
    }
  }

  # Bind this BGP config to our SMSv2 site
  where {
    site {
      ref {
        name      = var.xc_site_name
        namespace = var.xc_namespace
      }

      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
    }
  }

  depends_on = [volterra_external_connector.tgw]
}
