# AWS + F5 XC SMSv2 Hub-and-Spoke with TGW

## Architecture Overview

```
                    +-----------------------+
                    |   F5 Distributed      |
                    |   Cloud (XC)          |
                    |   Regional Edge       |
                    +-----------+-----------+
                                |
                          RE Tunnels
                                |
+-------------------------------+-------------------------------+
|                         Hub VPC (10.200.0.0/24)               |
|                                                               |
|  +------------------+    +------------------+                 |
|  | CE SLO (eth0)    |    | CE SLI (eth1)    |                 |
|  | 10.200.0.0/27    |    | 10.200.0.32/27   |                 |
|  | Internet egress  |    | BGP peering      |                 |
|  +--------+---------+    +--------+---------+                 |
|           |                       |                           |
|         [IGW]              [BGP ASN 64513]                    |
|                                   |                           |
|                    +--------------+--------------+            |
|                    | TGW Attachment Subnet       |            |
|                    | 10.200.0.64/28              |            |
+--------------------+-------------+--------------+------------+
                                   |
                     +-------------+-------------+
                     |  Transit Gateway          |
                     |  ASN 64512                |
                     |  Isolated Route Tables    |
                     +------+------------+------+
                            |            |
              +-------------+            +-------------+
              |                                        |
+-------------+-------------+          +--------------+------------+
|   Spoke 1 VPC (BU1)       |          |   Spoke 2 VPC (BU2)       |
|   10.100.0.0/16            |          |   10.0.0.0/16             |
|                            |          |                           |
|   Public:  10.100.0.0/24   |          |   Public:  10.0.1.0/24    |
|   Private: 10.100.1.0/24   |          |   Private: 10.0.0.0/24    |
|   [EC2 workload]           |          |   [EC2 workload]          |
+----------------------------+          +---------------------------+
```

### Connectivity Matrix

| Source | Destination | Allowed | Mechanism |
|--------|-------------|---------|-----------|
| Spoke 1 | Hub VPC | Yes | TGW route table propagation |
| Spoke 2 | Hub VPC | Yes | TGW route table propagation |
| Hub VPC | Spoke 1 | Yes | TGW route table propagation |
| Hub VPC | Spoke 2 | Yes | TGW route table propagation |
| Spoke 1 | Spoke 2 | **No** | No cross-propagation in TGW RTs |
| Spoke 2 | Spoke 1 | **No** | No cross-propagation in TGW RTs |

## Folder Layout

| Folder | Purpose | Provider |
|--------|---------|----------|
| `spoke_1/` | Spoke VPC "BU1" (10.100.0.0/16) + test EC2 | AWS ~> 6.55 |
| `spoke_2/` | Spoke VPC "BU2" (10.0.0.0/16) + test EC2 | AWS ~> 6.55 |
| `xc_smsv2_site/` | F5 XC Secure Mesh Site v2 + registration token | Volterra ~> 0.12 |
| `aws_tgw/` | Transit Gateway, Hub VPC, CE EC2 instance, TGW attachments + isolation | AWS ~> 6.55 |
| `xc_external_connector/` | CE-to-TGW BGP peering (external connector + BGP session) | Volterra ~> 0.12 |
| `xc_tgw/` | **(DEPRECATED)** Old TGW Orchestrated Site — do not use | Volterra 0.11 |

## Resource Chain (F5 XC side)

The CE-to-TGW BGP attachment uses three complementary Volterra resources:

```
volterra_securemesh_site_v2     defines the CE site + node + interfaces (SLO/SLI)
         |
         | (referenced by ce_site_reference)
         v
volterra_external_connector     defines transport to TGW (direct_connection = L2 adjacent)
         |
         | (referenced via external_connector=true flag on the BGP peer)
         v
volterra_bgp                    defines the BGP session (CE ASN 64513 <-> TGW ASN 64512)
```

## Deploy Order

Each folder is an independent Terraform root. Deploy them in this order, passing outputs as inputs to the next step.

### Step 1 — Spoke VPCs

Deploy `spoke_1/` and `spoke_2/` (can be done in parallel). These create the VPCs and subnets.

```bash
cd spoke_1 && terraform init && terraform apply
cd spoke_2 && terraform init && terraform apply
```

**Outputs needed for Step 3:**
- `spoke_1.aws_vpc` (VPC ID)
- `spoke_1.private_subnet_id`
- `spoke_2.aws_vpc` (VPC ID)
- `spoke_2.private_subnet_id`

### Step 2 — F5 XC Site Object

Deploy `xc_smsv2_site/`. This creates the SMSv2 site definition and registration token in F5 XC.

```bash
cd xc_smsv2_site && terraform init && terraform apply
```

**Outputs needed for Step 3:**
- `xc_smsv2_site.site_token` (registration token for CE cloud-init)
- `xc_smsv2_site.cluster_name`

### Step 3 — Hub Infrastructure (TGW + CE)

Deploy `aws_tgw/`. This creates the Transit Gateway, hub VPC, CE EC2 instance, and all TGW attachments with isolated route tables.

```bash
cd aws_tgw && terraform init && terraform apply \
  -var="spoke1_vpc_id=<from step 1>" \
  -var="spoke1_private_subnet_id=<from step 1>" \
  -var="spoke2_vpc_id=<from step 1>" \
  -var="spoke2_private_subnet_id=<from step 1>" \
  -var="xc_site_token=<from step 2>" \
  -var="xc_cluster_name=<from step 2>"
```

The CE instance will boot, run cloud-init with the site token, and register with F5 XC. The `volterra_registration_approval` resource in Step 2 will auto-approve the registration (polling for up to 30 minutes).

**Outputs needed for Step 4:**
- `aws_tgw.tgw_id` (for spoke route updates)
- `aws_tgw.ce_sli_private_ip` (CE SLI IP, but TGW peer IP is what the BGP resource needs)

### Step 3b — Update Spoke Routes

After the TGW is created, update the spokes to add hub-bound routes via TGW:

```bash
cd spoke_1 && terraform apply -var="tgw_id=<from step 3>"
cd spoke_2 && terraform apply -var="tgw_id=<from step 3>"
```

### Step 4 — BGP Peering

Deploy `xc_external_connector/`. This creates the external connector (direct L2 connection) and the BGP session between the CE and TGW.

```bash
cd xc_external_connector && terraform init && terraform apply \
  -var="xc_site_name=<from step 2>" \
  -var="tgw_bgp_peer_ip=<TGW attachment ENI IP>"
```

> **Note:** The `tgw_bgp_peer_ip` is the IP address AWS assigns to the TGW attachment ENI in the hub VPC. After Step 3, look up the ENI private IP assigned in the `hub-tgw-attach` subnet (`10.200.0.64/28`) via the AWS console or CLI:
> ```bash
> aws ec2 describe-network-interfaces \
>   --filters "Name=subnet-id,Values=<hub_tgw_subnet_id>" \
>             "Name=description,Values=*Transit Gateway*" \
>   --query 'NetworkInterfaces[0].PrivateIpAddress' \
>   --output text
> ```

## Future Work

The architecture is ready to accommodate F5 XC origin pools and VIP publication:

- **Origin Pool:** Discover a public website or internal service as an origin, configured via `volterra_origin_pool`.
- **VIP Publication:** Publish a Virtual IP on the CE SLI interface (facing the TGW/spokes) via `volterra_http_loadbalancer` with advertise policy targeting this site. Spokes will reach the VIP through the TGW.

These resources would go in a new folder (e.g., `xc_app_connect/`) deployed after the BGP peering is established.

## Key Design Decisions

- **CE deployment mode:** Single node (`disable_ha = true`), not managed by F5 cloud orchestration (`aws > not_managed`)
- **CE instance:** m5.2xlarge / 80GB gp3 (F5 minimum recommendation)
- **BGP ASNs:** TGW = 64512, CE = 64513 (private range)
- **Spoke isolation:** Enforced via separate TGW route tables with selective propagation (no spoke-to-spoke routes)
- **Source/dest check:** Disabled on both CE ENIs (CE is a network virtual appliance)
- **Provider versions:** AWS ~> 6.55, Volterra ~> 0.12, Terraform >= 1.5.0
