# Session State — AWS XC TGW Spokes Project

**Last updated**: 2026-07-19
**Branch**: `feature/smsv2-tgw-bgp`
**Last commit**: `5579b94` — "Fix hub_vpc_cidr default in spokes to match actual hub VPC CIDR"

---

## Project Goal

Deploy an F5 XC Customer Edge (CE) as an SMSv2 "not_managed" site in AWS, connected to spoke VPCs via AWS Transit Gateway with spoke isolation. Spokes are isolated from each other — no spoke-to-spoke traffic. All spoke traffic to the hub transits through the CE.

## Architecture

```
spoke_1 (10.100.0.0/16) ──┐
                           ├── AWS TGW (spoke isolation) ── Hub VPC (10.110.0.0/16) ── F5 XC CE ── F5 XC REs
spoke_2 (10.0.0.0/16)  ──┘
```

Spokes are intentionally isolated from each other at the TGW level — each spoke's TGW route table only propagates the hub, not the other spoke.

## Current State — FULLY DEPLOYED

All infrastructure is deployed and operational as of 2026-07-19.

### Deployed Resources

| Component | Key IDs | CIDR | Status |
|-----------|---------|------|--------|
| **spoke_1** (BU1) | VPC: `vpc-0abb122629c17b56c`, Subnet: `subnet-0253cf770efae4832` | 10.100.0.0/16 | Deployed |
| **spoke_2** (BU2) | VPC: `vpc-0821e2a2c3bc24b8a`, Subnet: `subnet-0519a27c0c983bca0` | 10.0.0.0/16 | Deployed |
| **ce_vpc** (Hub) | VPC: `vpc-0faf252f6af13cb57` | 10.110.0.0/16 | Deployed |
| **CE instance** | `i-0cc3d9ff5d73b1dbd` | SLO: 15.157.83.120 / SLI: 10.110.2.119 | **ONLINE** |
| **CE site** | `aws-ce-site1` (uid: `dfcdf227-4e1d-496e-a3b9-4b14923d79d7`) | — | **ONLINE** |
| **Transit Gateway** | `tgw-0a6133b153328a5e1` (ASN 64512) | — | Deployed |
| **Hub TGW attachment** | `tgw-attach-0831ced6b6a67b82c` | — | Deployed |

### CE Networking Details

| Interface | ENI | Private IP | Subnet |
|-----------|-----|-----------|--------|
| SLO (eth0, outside) | `eni-011ddd628c55ed967` | 10.110.1.111 | `subnet-03792eed5f9e25c5f` (outside) |
| SLI (eth1, inside) | `eni-08398b82baf0ec057` | 10.110.2.119 | `subnet-026f062853f1d5332` (inside) |
| — | — | — | `subnet-095a0dd4984bbe3ec` (TGW attachment) |
| EIP | `eipalloc-06bc591c80ff58474` | 15.157.83.120 | — |

### Routing Summary

| Route | Path |
|-------|------|
| spoke_1 private → 10.110.0.0/16 | via TGW `tgw-0a6133b153328a5e1` |
| spoke_2 private → 10.110.0.0/16 | via TGW `tgw-0a6133b153328a5e1` |
| Hub SLI subnet → 10.100.0.0/16 | via TGW (spoke_1) |
| Hub SLI subnet → 10.0.0.0/16 | via TGW (spoke_2) |
| Hub TGW subnet → 0.0.0.0/0 | via CE SLI ENI `eni-08398b82baf0ec057` |
| TGW spoke_1 RT | propagation from hub only (isolated) |
| TGW spoke_2 RT | propagation from hub only (isolated) |
| TGW hub RT | propagation from both spokes |

## Deployment Order (Completed)

```
1. spoke_1/    → terraform apply                                    ✅ Deployed
2. spoke_2/    → terraform apply                                    ✅ Deployed
3. ce_vpc/     → VES_P12_PASSWORD='...' terraform apply             ✅ Deployed, CE ONLINE
4. aws_tgw/    → terraform apply (tfvars updated with real outputs) ✅ Deployed (21 resources)
5. spoke_1/    → terraform apply -var='tgw_id=tgw-...'              ✅ TGW route added
   spoke_2/    → terraform apply -var='tgw_id=tgw-...'              ✅ TGW route added
```

## Monitoring CE Registration

### Extract certs from P12 for API calls

```bash
P12="../../f5-sa-6-17-26.api-creds.p12"
CERT_DIR="/tmp/f5xc-certs"
mkdir -p "$CERT_DIR"
openssl pkcs12 -in "$P12" -clcerts -nokeys -out "$CERT_DIR/client.crt" -passin 'pass:<VES_P12_PASSWORD>' -legacy
openssl pkcs12 -in "$P12" -nocerts -nodes -out "$CERT_DIR/client.key" -passin 'pass:<VES_P12_PASSWORD>' -legacy
```

### One-shot status check

```bash
curl -s --cert /tmp/f5xc-certs/client.crt --key /tmp/f5xc-certs/client.key \
  'https://f5-sa.console.ves.volterra.io/api/config/namespaces/system/securemesh_site_v2s/aws-ce-site1' \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
spec = d.get('spec', {})
print('site_state:', spec.get('site_state'))
print('site_errors:', spec.get('site_errors', []))
print('sw_version:', spec.get('volterra_software_version'))
print('os_version:', spec.get('operating_system_version'))
labels = d.get('metadata', {}).get('labels', {})
print('hw-model:', labels.get('hw-model', 'n/a'))
print('host-os:', labels.get('host-os-version', 'n/a'))
"
```

### Poll until ONLINE (watch loop)

```bash
while true; do
  state=$(curl -s --cert /tmp/f5xc-certs/client.crt --key /tmp/f5xc-certs/client.key \
    'https://f5-sa.console.ves.volterra.io/api/config/namespaces/system/securemesh_site_v2s/aws-ce-site1' \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('spec',{}).get('site_state','UNKNOWN'))")
  echo "$(date '+%H:%M:%S') CE state: $state"
  if [ "$state" = "ONLINE" ]; then
    echo "CE IS ONLINE — ready to proceed!"
    break
  fi
  sleep 30
done
```

### CE Registration Timeline (observed 2026-07-19)

CE provisioning took ~30 minutes total:
- **0-9 min**: `PROVISIONING` — CE booting, registering with F5 XC
- **9-10 min**: `UPGRADING` — software upgrade begins
- **10-29 min**: `UPGRADING` — downloading and applying new software version
- **29 min**: Brief `PROVISIONING` — post-upgrade reboot
- **30 min**: `ONLINE` — fully registered, data plane + control plane healthy

## What Works (Validated)

The key breakthrough was discovering the correct SMSv2 "not_managed" pattern by comparing to `another_ce_build/` (a reference example). The CE successfully registered and reached 100% health (data plane + control plane) in ~30 minutes.

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

### Bug Fix Applied This Session

- `hub_vpc_cidr` default in `spoke_1/variables.tf` and `spoke_2/variables.tf` was `10.200.0.0/24` (stale placeholder). Fixed to `10.110.0.0/16` to match the actual hub VPC CIDR.

## Folder Structure

| Folder | Purpose | Provider(s) | Status |
|---|---|---|---|
| `spoke_1/` | Spoke 1 VPC (BU1, 10.100.0.0/16) + test instance | AWS | **Deployed** with TGW route |
| `spoke_2/` | Spoke 2 VPC (BU2, 10.0.0.0/16) + test instance | AWS | **Deployed** with TGW route |
| `ce_vpc/` | Hub VPC (10.110.0.0/16) + CE + SMSv2 site + token | AWS + Volterra | **Deployed**, CE ONLINE |
| `aws_tgw/` | TGW + 3 VPC attachments + route tables + routing | AWS only | **Deployed** (21 resources) |
| `another_ce_build/` | Reference example that proved the working pattern | AWS + Volterra | Reference only — don't deploy |
| `xc_smsv2_site/` | Old separate XC site config (superseded by ce_vpc) | Volterra | Obsolete |
| `xc_tgw/` | XC TGW site config (not part of current work) | Volterra | Unused |

## Key Outputs / Wiring

```
spoke_1 outputs:  vpc_id, private_subnet_id          → aws_tgw inputs
spoke_2 outputs:  vpc_id, private_subnet_id          → aws_tgw inputs
ce_vpc outputs:   vpc_id, tgw_subnet_id,             → aws_tgw inputs
                  sli_subnet_id, sli_eni_id
aws_tgw outputs:  tgw_id                             → spoke_1/spoke_2 -var='tgw_id=...'
```

## Credentials

- **AWS region**: `ca-central-1`
- **AWS key pair**: `netta-aws-ca-cent-7-2025`
- **F5 XC tenant**: `f5-sa` (`f5-sa-rnxeudss`)
- **F5 XC API URL**: `https://f5-sa.console.ves.volterra.io/api`
- **P12 file**: `../../f5-sa-6-17-26.api-creds.p12` (relative from ce_vpc/)
- **VES_P12_PASSWORD**: must be set as env var when running ce_vpc
- **tfvars files**: excluded by .gitignore, contain AWS creds — must be recreated from .example or prior values

## Teardown Order (reverse of deploy)

```
1. cd spoke_1 && terraform apply -var='tgw_id=' -auto-approve   # remove TGW route
   cd spoke_2 && terraform apply -var='tgw_id=' -auto-approve   # remove TGW route
2. cd aws_tgw && terraform destroy -auto-approve
3. cd ce_vpc && VES_P12_PASSWORD='...' terraform destroy -auto-approve
4. cd spoke_1 && terraform destroy -auto-approve
   cd spoke_2 && terraform destroy -auto-approve
```

## Next Steps / Future Work

- Test spoke-to-hub connectivity (ping CE SLI 10.110.2.119 from spoke test instances)
- IPsec/GRE tunnel from CE to TGW + BGP peering (not yet built)
- External connector for internet egress through CE

## VPC Quota Note

ca-central-1 has a 5 VPC limit. With 3 VPCs deployed (hub + 2 spokes) plus potentially 2 existing (mora_vpc, ves-vpc-auto-v-mora), you may be at 5/5. If you hit the limit, delete old VPCs or request a quota increase.
