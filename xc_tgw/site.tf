resource "volterra_aws_tgw_site" "tgw_site" {
  name      = "netta-tgw-site-demo"
  namespace = "system"
  vpc_attachments {
    vpc_list {
      vpc_id = "vpc-0ce42e5fd7dff7c61"
    }
    vpc_list {
      vpc_id = "vpc-027445036839330dd"
    }
  }

  aws_parameters {
    aws_certified_hw = "aws-byol-multi-nic-voltmesh"
    aws_region       = "us-east-2"

    az_nodes {
      aws_az_name = "us-east-2a"

      // One of the arguments from this list "reserved_inside_subnet inside_subnet" must be set
      reserved_inside_subnet = true
      disk_size              = "80"

      outside_subnet {
        // One of the arguments from this list "subnet_param existing_subnet_id" must be set

        subnet_param {
          ipv4 = "192.168.1.0/24"
          #   ipv6 = "1234:568:abcd:9100::/64"
        }
      }

      workload_subnet {
        // One of the arguments from this list "existing_subnet_id subnet_param" must be set

        subnet_param {
          ipv4 = "192.168.0.0/24"
          #   ipv6 = "1234:568:abcd:9100::/64"
        }
      }
      inside_subnet {
        subnet_param {
          ipv4 = "192.168.2.0/24"
        }
      }
    }

    // One of the arguments from this list "aws_cred assisted" must be set

    aws_cred {
      name      = var.cred
      namespace = "system"
      tenant    = var.tenant
    }
    disk_size     = "80"
    instance_type = "t3.xlarge"
    // One of the arguments from this list "disable_internet_vip enable_internet_vip" must be set
    disable_internet_vip = true
    // One of the arguments from this list "f5xc_security_group custom_security_group" must be set
    f5xc_security_group = true
    // One of the arguments from this list "new_vpc vpc_id" must be set
    new_vpc {
      name_tag     = "tgw-demo"
      primary_ipv4 = "192.168.0.0/22"
      autogenerate = true
    }
    # vpc_id = "vpc-12345678901234567"

    ssh_key = var.ssh_key
    // One of the arguments from this list "new_tgw existing_tgw" must be set

    new_tgw {
      // One of the arguments from this list "system_generated user_assigned" must be set
      system_generated = true
    }
    // One of the arguments from this list "nodes_per_az total_nodes no_worker_nodes" must be set
    # nodes_per_az = "1"
    # total_nodes = "1"
    no_worker_nodes = true

  }

  // One of the arguments from this list "block_all_services blocked_services default_blocked_services" must be set
  default_blocked_services = true

  // One of the arguments from this list "direct_connect_disabled direct_connect_enabled private_connectivity" must be set
  direct_connect_disabled = true


  // One of the arguments from this list "logs_streaming_disabled log_receiver" must be set

  #   log_receiver {
  #     name      = "test1"
  #     namespace = "staging"
  #     tenant    = "acmecorp"
  #   }
}

resource "volterra_tf_params_action" "aws_tgw_site-terraform-params-action" {
  site_name = "netta-tgw-site-demo"
  site_kind = "aws_tgw_site"
  action = "apply"
  depends_on = [ volterra_aws_tgw_site.tgw_site ]
  wait_for_action = true
}