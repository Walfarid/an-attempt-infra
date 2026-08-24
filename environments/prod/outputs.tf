output "compartment_ocid" {
  description = "OCID of the walfa-prod compartment."
  value       = oci_identity_compartment.this.id
}

output "availability_domain" {
  description = "Availability domain everything was placed in."
  value       = local.availability_domain
}

output "app_public_ip" {
  description = "Reserved public IP of the app VM - target of the Cloudflare A record."
  value       = module.app_vm.public_ip
}

output "app_private_ip" {
  description = "Private IP of the app VM."
  value       = module.app_vm.private_ip
}

output "watcher_public_ip" {
  description = "Public IP of the watcher VM. SSH only; Uptime-Kuma UI via SSH tunnel. Empty while watcher_enabled is false."
  value       = var.watcher_enabled ? module.watcher_vm[0].public_ip : ""
}

output "watcher_kuma_tunnel_command" {
  description = "How to reach the Uptime-Kuma UI (loopback-only by design). Empty while watcher_enabled is false."
  value       = var.watcher_enabled ? "ssh -L 3001:127.0.0.1:3001 ubuntu@${module.watcher_vm[0].public_ip}" : "(watcher disabled - set watcher_enabled = true after requesting E2.Micro quota)"
}

output "mysql_hostname" {
  description = "Managed MySQL hostname (resolves inside the VCN)."
  value       = module.mysql.hostname
}

output "mysql_admin_username" {
  description = "Managed MySQL admin username."
  value       = module.mysql.admin_username
}

output "mysql_admin_password" {
  description = "Managed MySQL admin password (rotate out-of-band)."
  value       = random_password.db_admin.result
  sensitive   = true
}

output "mysql_app_username" {
  description = "Application database username provisioned on first boot."
  value       = var.app_db_user
}

output "mysql_app_password" {
  description = "Application database user password."
  value       = random_password.db_app.result
  sensitive   = true
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for Object Storage."
  value       = local.s3_endpoint
}

output "s3_bucket_name" {
  description = "Media bucket name."
  value       = module.objectstore.bucket_name
}

output "ocir_image_path" {
  description = "Full image reference CI should build and push."
  value       = local.app_image
}

output "github_secrets" {
  description = "Values for the repository secrets used by deploy.yml."
  value = {
    OCIR_REGISTRY   = var.ocir_registry
    OCIR_USERNAME   = module.registry.login_username
    OCIR_AUTH_TOKEN = module.registry.auth_token
    OCIR_IMAGE      = local.app_image
    DEPLOY_HOST     = module.app_vm.public_ip
    DEPLOY_USER     = "ubuntu"
    DEPLOY_PATH     = "/opt/walfa"
    DEPLOY_SSH_KEY  = "(your private key authorized on the app VM; not managed here)"
  }
  sensitive = true
}

output "post_apply_checklist" {
  description = "Manual steps that Terraform cannot do for you."
  value = join("\n", [
    "1. scp ${abspath(path.module)}/generated/walfa.env ubuntu@${module.app_vm.public_ip}:/opt/walfa/.env",
    "2. Cloudflare: proxied A record -> ${module.app_vm.public_ip}; SSL mode Full",
    "3. Paste github_secrets into the repository settings",
    "4. Download the MySQL CA bundle from Console > MySQL HeatWave > DB system > Connections",
    "   and place it at /opt/walfa/secrets/mysql-ca.pem on the app VM",
  ])
}
