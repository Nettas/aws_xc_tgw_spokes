# Changelog

## 2025-07-18 08:45 EDT — Replace TGW Orchestrated Site with SMSv2 + BGP Peering

### Summary

Replaced the deprecated F5 XC "TGW Orchestrated Site" (`xc_tgw/`) with the newer Secure Mesh Site v2 (SMSv2) architecture. The CE is now deployed as a self-managed EC2 instance in a dedicated hub VPC and peers with an AWS Transit Gateway over BGP. Spoke isolation is enforced via separate TGW route tables.

### Provider Schema Investigation

Before writing any HCL, the Volterra provider **v0.12.2** (latest) was initialized and its schema inspected via `terraform providers schema -json`. This confirmed that CE-to-TGW BGP attachment requires **three complementary resources**:

| Resource | Role |
|----------|------|
| `volterra_securemesh_site_v2` | Defines the CE site, node, and interfaces (SLO/SLI) |
| `volterra_external_connector` | Defines transport to TGW (`direct_connection` = L2 adjacent) |
| `volterra_bgp` | Defines the BGP session (CE ASN 64513 ↔ TGW ASN 64512) |

The `volterra_securemesh_site_v2` resource has **no built-in TGW/BGP blocks** — the external connector and BGP resources are required separately.

---

### New Folders Created

#### `aws_tgw/` — AWS Hub Infrastructure (5 files)

| File | Contents |
|------|----------|
| `providers.tf` | AWS provider `~> 6.55`, ca-central-1 |
| `variables.tf` | Credentials, hub VPC CIDRs, TGW ASN (64512), spoke VPC/subnet IDs (passed in), CE config (m5.2xlarge, 80GB), SSH trusted CIDR |
| `vpc.tf` | Hub VPC (`10.200.0.0/24`), 3 subnets (SLO `10.200.0.0/27`, SLI `10.200.0.32/27`, TGW `10.200.0.64/28`), IGW, 3 route tables with spoke→TGW and return-path routes |
| `tgw.tf` | Transit Gateway (ASN 64512, default RT disabled), 3 VPC attachments (hub + 2 spokes), 3 isolated route tables, 4 propagation rules enforcing spoke1↔hub / spoke2↔hub / no spoke↔spoke |
| `ce.tf` | CE AMI data source (Volterra owner `434481986642`), SLO + SLI security groups, 2 ENIs with `source_dest_check = false`, EIP for SLO, CE EC2 instance with cloud-init user_data (site token + cluster name) |
| `outputs.tf` | `tgw_id`, `hub_vpc_id`, `hub_sli_subnet_id`, `ce_sli_private_ip`, `ce_slo_public_ip`, `ce_instance_id`, `hub_tgw_attachment_id` |

#### `xc_smsv2_site/` — F5 XC Site Definition (4 files)

| File | Contents |
|------|----------|
| `providers.tf` | Volterra provider `~> 0.12`, P12 cert auth |
| `variables.tf` | API auth (P12 file path + tenant URL), site name, namespace, optional static IPs for SLO/SLI, SSH key, lat/long |
| `site.tf` | `volterra_token` for registration, `volterra_securemesh_site_v2` (AWS, `not_managed`, single node with SLO eth0 DHCP + SLI eth1 DHCP, `disable_ha = true`), `volterra_registration_approval` (auto-approve, polls up to 30 min) |
| `outputs.tf` | `site_name`, `site_token` (sensitive), `cluster_name` |

#### `xc_external_connector/` — BGP Peering (4 files)

| File | Contents |
|------|----------|
| `providers.tf` | Volterra provider `~> 0.12`, P12 cert auth |
| `variables.tf` | API auth, site name reference, CE ASN (64513), TGW ASN (64512), TGW BGP peer IP |
| `connector.tf` | `volterra_external_connector` with `direct_connection {}` + `volterra_bgp` (CE ASN 64513, peer ASN 64512, `external_connector = true`, bound to site SLI network) |
| `outputs.tf` | `external_connector_name`, `bgp_name` |

---

### Modified Folders

#### `spoke_1/` — Spoke VPC "BU1" (10.100.0.0/16)

| File | Change |
|------|--------|
| `providers.tf` | **Rewritten** — added `required_providers` block, pinned AWS to `~> 6.55`, added `required_version >= 1.5.0` |
| `variables.tf` | `aws_region` default → `ca-central-1`, `az` default → `ca-central-1a`, `awsRegion` default → `ca-central-1`. Added new variables: `tgw_id` (default `""`) and `hub_vpc_cidr` (default `10.200.0.0/24`) |
| `network.tf` | **Rewritten** — added dedicated private route table (`bu1-private-rt`) with conditional `hub_vpc_cidr → TGW` route (only created when `tgw_id` is set). Fixed public RT association to public subnet (was incorrectly associated to private subnet) |
| `output.tf` | Added `private_subnet_id` output (needed by `aws_tgw/` for TGW attachment) |
| `.terraform.lock.hcl` | **Deleted** — old lock pinned AWS 6.9.0, incompatible with `~> 6.55` constraint |

#### `spoke_2/` — Spoke VPC "BU2" (10.0.0.0/16)

| File | Change |
|------|--------|
| `providers.tf` | **Rewritten** — same structure as spoke_1 (was pinned to AWS 5.31.0 with `skip_region_validation`) |
| `variables.tf` | `aws_region` default → `ca-central-1`. Added `tgw_id` and `hub_vpc_cidr` variables |
| `network.tf` | **Rewritten** — added private route table (`bu2-private-rt`) with conditional hub→TGW route. Fixed public RT association to public subnet (was incorrectly associated to private subnet) |
| `output.tf` | Added `private_subnet_id` output |
| `.terraform.lock.hcl` | **Deleted** — old lock pinned AWS 5.31.0 |

---

### Unchanged

| Item | Note |
|------|------|
| `xc_tgw/` | Old deprecated folder left in place — retire at your discretion |
| `spoke_1/vpc.tf` | VPC CIDR `10.100.0.0/16` preserved |
| `spoke_1/ec2.tf` | Test EC2 instance unchanged |
| `spoke_1/sg.tf` | Security group unchanged |
| `spoke_2/vpc.tf` | VPC CIDR `10.0.0.0/16` preserved |
| `spoke_2/ec2.tf` | Test EC2 instance unchanged |
| `spoke_2/sg.tf` | Security group unchanged |
| `.gitignore` | Unchanged (already excludes `*.tfvars`, `*.tfstate`, `.terraform/`) |

---

### Validation

All four active folders pass `terraform validate`:

```
aws_tgw/                 ✅ Success
xc_smsv2_site/           ✅ Success
xc_external_connector/   ✅ Success (1 deprecation warning on description attr — cosmetic)
spoke_1/                 ✅ Success
spoke_2/                 ✅ Success
```

### Bug Fix

The `volterra_site_state` resource was initially included in `xc_smsv2_site/` to wait for site ONLINE status, but schema validation revealed it only supports `when = "create" | "delete"` and `state = "REREGISTRATION" | "DECOMMISSIONING"`. It is a lifecycle control resource, not a status-polling resource. Removed and replaced with a comment noting that `volterra_registration_approval` handles the wait.
