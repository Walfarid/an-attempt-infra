# walfa infrastructure on OCI (Always Free)

Terraform stack that provisions the complete walfa runtime on Oracle Cloud
Infrastructure in `ap-singapore-1`, with remote state stored in OCI Object
Storage.

## What gets provisioned

```
                        Cloudflare (proxied, SSL mode Full)
                                      |
        compartment: walfa-prod  -  region: ap-singapore-1
+---------------------------------------------------------------------+
| VCN 10.0.0.0/16 + Internet Gateway                                  |
|                                                                     |
| public subnet 10.0.1.0/24          private subnet 10.0.2.0/24       |
|   walfa-app  VM.Standard.A1.Flex     walfa-mysql  MySQL.Free        |
|     Ubuntu 24.04 arm64, 4 OCPU/24GB    ingress: 3306 from           |
|     50 GB boot @ 20 VPU, Docker         10.0.1.0/24 only            |
|     reserved public IP                                              |
|                                                                     |
| public subnet 10.0.3.0/24                                           |
|   walfa-watcher VM.Standard.E2.1.Micro                              |
|     Uptime-Kuma on loopback only                                    |
|     inbound: SSH from your CIDR exclusively                         |
+---------------------------------------------------------------------+

Object Storage : walfa-media bucket + Customer Secret Key (S3-compatible)
                 walfa-tfstate bucket (bootstrap, versioned)
Registry       : sin.ocir.io/<namespace>/walfa-app + auth token
```

Security lists: app VM accepts 80/tcp, 443/tcp, 443/udp from anywhere and
22/tcp only from `ssh_allowed_cidrs`; the watcher accepts nothing but SSH from
`ssh_allowed_cidrs`; MySQL accepts 3306/tcp only from the app subnet.

## Repository layout

```
infra/
├── bootstrap/                  one-time local-state run: state bucket + backend key
├── environments/prod/          the root module you apply for real workloads
│   ├── backend.tf              partial s3 backend (OCI S3 compatibility)
│   ├── main.tf                 compartment + module wiring + rendered .env
│   └── generated/walfa.env     sensitive output written at apply time
└── modules/
    ├── network/                VCN, IGW, 3 subnets, route table, security lists
    ├── compute-app/            A1 instance + reserved IP + Docker + DB bootstrap
    ├── compute-watcher/        E2.1.Micro + Uptime-Kuma (loopback)
    ├── mysql/                  managed MySQL.Free in the private subnet
    ├── objectstore/            media bucket + customer secret key
    └── registry/               OCIR repository + auth token
```

## Free-tier facts baked into defaults

| Resource | Setting | Note |
|---|---|---|
| A1 Flex | 4 OCPU / 24 GB | free on PAYG tenancies; **pure Always-Free tenancies are capped at 2 OCPU / 12 GB since 2026-08-18** — lower `app_ocpus` / `app_memory_gbs` if that is you |
| Boot volumes | 20 VPU/GB | Higher Performance; VPU settings do not add cost to Always-Free volumes |
| Block storage | 50 + 47 GB | pooled limit is 200 GB |
| Micro VMs | 1 of 2 | watcher |
| MySQL | `MySQL.Free` | standalone single node, fixed 50 GB storage, 1-day backups, no HA |

## Prerequisites

- Terraform >= 1.9 (tested with 1.15.x). Note: provider blocks in
  `required_providers` use the object syntax required by Terraform 1.15.
- OCI CLI configured (`oci setup config`) with a profile that can manage
  compartments, compute, MySQL, object storage, artifacts and identity
  credentials.
- Your IAM user OCID and username (Console > Profile icon > User settings).
- An SSH key pair whose public key will be authorized on both VMs.
- The OCI S3 layer does not support state locking: never run two applies
  concurrently.

## Step 1 - Bootstrap remote state (once)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in the two OCIDs
terraform init
terraform apply

# Capture the backend credentials for this shell:
export AWS_ACCESS_KEY_ID="$(terraform output -raw access_key)"
export AWS_SECRET_ACCESS_KEY="$(terraform output -raw secret_key)"
terraform output state_bucket_name   # note it
terraform output namespace           # note it
```

## Step 2 - Apply the prod environment

```bash
cd ../environments/prod
cp backend.config.hcl.example backend.config.hcl
#   bucket   = <state_bucket_name>
#   endpoint = https://<namespace>.compat.objectstorage.ap-singapore-1.oraclecloud.com
cp terraform.tfvars.example terraform.tfvars    # REQUIRED fields marked inside

terraform init -backend-config=backend.config.hcl
terraform plan
terraform apply
```

The apply writes every infra-owned value into `generated/walfa.env`
(mode 0600) and prints a checklist via `terraform output post_apply_checklist`.

A1 capacity errors (`Out of host capacity`) are routine in ap-singapore-1;
simply re-run the plan until it goes through.

## Step 3 - Manual wiring after apply

1. **Server .env** - fill `WORKOS_SECRET`, `TURNSTILE_SITE_KEY`,
   `TURNSTILE_SECRET_KEY` in `generated/walfa.env`, then:
   ```bash
   ssh ubuntu@<app_public_ip> 'sudo mkdir -p /opt/walfa'
   scp generated/walfa.env ubuntu@<app_public_ip>:/opt/walfa/.env
   ```
2. **MySQL CA bundle** - Console > MySQL HeatWave > your DB system >
   Connections tab shows the security certificate; download the CA bundle and
   place it at `/opt/walfa/secrets/mysql-ca.pem`. The first-boot bootstrap
   retries for up to 40 minutes, so installing the bundle afterwards still
   works if you re-run the service:
   ```bash
   sudo systemctl enable --now walfa-bootstrap-db.service
   journalctl -u walfa-bootstrap-db.service -f
   ```
3. **Cloudflare DNS** - proxied `A` record for your domain pointing at
   `app_public_ip`; set SSL/TLS mode to **Full** (switch to Full (strict)
   once your origin certificate chain is trusted).
4. **GitHub secrets** - `terraform output -json github_secrets` gives every
   value for `deploy.yml`: `OCIR_REGISTRY`, `OCIR_USERNAME`, `OCIR_AUTH_TOKEN`,
   `OCIR_IMAGE`, `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, plus
   `DEPLOY_SSH_KEY` (your own private key; its public half must be listed in
   `app_ssh_public_keys`).
5. **First deploy** - push an image and let GitHub Actions bring the stack up.

## Day-2 operations

- **Uptime-Kuma UI**: `ssh -L 3001:127.0.0.1:3001 ubuntu@<watcher_ip>` then
  open http://localhost:3001. It is deliberately unreachable from the network.
- **MySQL admin password**: rotate in Console or SQL, then update any local
  references; Terraform ignores drift on it by design.
- **SSH source IP changed**: edit `ssh_allowed_cidrs` in tfvars and re-apply -
  the rules are dynamic blocks, no code edits needed.
- **Tear-down order**: `terraform destroy` in `environments/prod`. The state
  bucket outlives the stack on purpose.

## Cost safety

At these defaults everything sits inside Always Free allowances. The two
things that can start billing on an upgraded (PAYG) account are Object
Storage beyond ~10 GB of standard storage as `walfa-media` grows, and egress
beyond 10 TB/month. Everything else in this stack is capped by construction.
