# Session State — AWS XC TGW Spokes Project

**Last updated**: 2026-07-18
**Branch**: `feature/smsv2-tgw-bgp`
**Last commit**: `8876de2` — "Rewrite ce_vpc and aws_tgw to use proven SMSv2 not_managed pattern"

---

## Project Goal

Deploy an F5 XC Customer Edge (CE) as an SMSv2 "not_managed" site in AWS, connected to spoke VPCs via AWS Transit Gateway with spoke isolation. All traffic between spokes transits through the CE.

## Architecture

```
spoke_1 (10.100.0.0/16) ──┐
                           ├── AWS TGW (spoke isolation) ── Hub VPC (10.110.0.0/16) ── F5 XC CE ── F5 XC REs
spoke_2 (10.0.0.0/16)  ──┘
```

## Deployment Order

```
1. spoke_1/    → Spoke 1 VPC + test instance
2. spoke_2/    → Spoke 2 VPC + test instance
3. ce_vpc/     → Hub VPC + SMSv2 CE (registers with F5 XC)
4. aws_tgw/    → TGW + attachments + routing (wires everything together)
5. (spokes)    → Re-apply spokes with tgw_id to enable TGW routes
```

## Current State

- **All infrastructure is DESTROYED** — clean slate, nothing deployed
- **All code is committed and pushed** to `feature/smsv2-tgw-bgp`
- **aws_tgw has not been deployed yet** — we validated the code (`terraform validate` passed, plan shows 21 resources) but haven't applied it

## What Works (Validated)

The key breakthrough was discovering the correct SMSv2 "not_managed" pattern by comparing to `another_ce_build/` (a reference example). The CE successfully registered and reached 100% health (data plane + control plane) in ~10 minutes.

### Critical Pattern — What Makes CE Registration Work

1. **Empty `not_managed {}`** — do NOT define node_list, hostname, type, or interfaces in the site object. Let the CE self-identify during registration.
2. **EC2 tags**: `ves-io-site-name` and `kubernetes.io/cluster/<site-name> = "owned"` are required on the CE instance.
3. **`cloudinit_config` data source** with `yamlencode()` — writes `/etc/vpm/user_data` with `token: <JWT>`.
4. **Volterra provider `>=0.11.42`** (resolves to `0.12.2`) — NOT pinned to `0.11.49`.
5. **No `volterra_cloud_credentials`** needed for not_managed deployments.
6. **`source_dest_check = false`** on BOTH SLO and SLI ENIs.
7. **`software_settings`** block with `default_os_version = true` and `default_sw_version = true`.

### What Does NOT Work

- Defining `node_list` with hostname/type/interfaces in `not_managed {}` — CE registers as wrong node type or fails to register entirely.
- Legacy JSON `jsonencode({Token, ClusterName})` user_data format — CE doesn't find its token.
- Missing `ves-io-site-name` EC2 tag — CE can't associate with the site object.
- Pinning volterra provider to `0.11.49` with `0.12.x` schema syntax (or vice versa).

## Folder Structure

| Folder | Purpose | Provider(s) | Status |
|---|---|---|---|
| `spoke_1/` | Spoke 1 VPC (BU1, 10.100.0.0/16) + test instance | AWS | Ready, has conditional TGW route |
| `spoke_2/` | Spoke 2 VPC (BU2, 10.0.0.0/16) + test instance | AWS | Ready, has conditional TGW route |
| `ce_vpc/` | Hub VPC (10.110.0.0/16) + CE + SMSv2 site + token | AWS + Volterra | **Rewritten & validated** |
| `aws_tgw/` | TGW + 3 VPC attachments + route tables + routing | AWS only | **Rewritten & validated (not yet applied)** |
| `another_ce_build/` | Reference example that proved the working pattern | AWS + Volterra | Reference only — don't deploy |
| `xc_smsv2_site/` | Old separate XC site config (superseded by ce_vpc) | Volterra | Obsolete — state already destroyed |
| `xc_tgw/` | XC TGW site config (not part of current work) | Volterra | Unused |

## Key Outputs / Wiring

When deployed, outputs flow between configs:

```
spoke_1 outputs:  aws_vpc, private_subnet_id     → aws_tgw inputs
spoke_2 outputs:  aws_vpc, private_subnet_id     → aws_tgw inputs
ce_vpc outputs:   vpc_id, tgw_subnet_id,         → aws_tgw inputs
                  sli_subnet_id, sli_eni_id
aws_tgw outputs:  tgw_id                         → spoke_1/spoke_2 inputs (re-apply)
```

## Credentials

- **AWS region**: `ca-central-1`
- **AWS key pair**: `netta-aws-ca-cent-7-2025`
- **F5 XC tenant**: `f5-sa` (`f5-sa-rnxeudss`)
- **F5 XC API URL**: `https://f5-sa.console.ves.volterra.io/api`
- **P12 file**: `../../f5-sa-6-17-26.api-creds.p12` (relative from ce_vpc/)
- **VES_P12_PASSWORD**: must be set as env var when running ce_vpc
- **tfvars files**: excluded by .gitignore, contain AWS creds — must be recreated from .example or prior values

## Next Steps

1. Deploy spokes: `cd spoke_1 && terraform apply`, `cd spoke_2 && terraform apply`
2. Deploy ce_vpc: `cd ce_vpc && VES_P12_PASSWORD='<pwd>' terraform apply` — wait for CE to reach 100% health
3. Update `aws_tgw/terraform.tfvars` with real output values from spokes and ce_vpc
4. Deploy aws_tgw: `cd aws_tgw && terraform apply`
5. Re-apply spokes with `tgw_id` from aws_tgw output to enable TGW routes
6. Test spoke-to-spoke connectivity through the CE
7. Future: IPsec/GRE tunnel from CE to TGW + BGP peering (not yet built)

## VPC Quota Note

ca-central-1 has a 5 VPC limit. With 3 new VPCs (hub + 2 spokes) plus 2 existing (mora_vpc, ves-vpc-auto-v-mora), you'll be at 5/5. If you hit the limit, delete old VPCs or request a quota increase.
