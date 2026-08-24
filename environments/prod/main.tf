# Dedicated compartment keeps the whole stack isolated and deletable in one go.
resource "oci_identity_compartment" "this" {
  name        = var.compartment_name
  description = "walfa ${var.environment} infrastructure, managed by Terraform"
}

data "oci_identity_availability_domains" "this" {
  compartment_id = oci_identity_compartment.this.id
}

locals {
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name

  s3_endpoint = "https://${module.objectstore.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"

  app_image = "${var.ocir_registry}/${module.registry.namespace}/${var.ocir_repository_name}:${var.app_image_tag}"
}

# Strong but shell-safe passwords for MySQL accounts. All four character
# classes included: OCI rejects purely-alphanumeric admin passwords on some
# MySQL shapes ("adminPassword ... may not be valid").
resource "random_password" "db_admin" {
  length      = 28
  special     = true
  override_special = "_#%+-"
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "random_password" "db_app" {
  length      = 28
  special     = true
  override_special = "_#%+-"
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

module "network" {
  source = "../../modules/network"

  compartment_id = oci_identity_compartment.this.id
  tags           = local.common_tags

  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  app_subnet_cidr     = "10.0.1.0/24"
  db_subnet_cidr      = "10.0.2.0/24"
  watcher_subnet_cidr = "10.0.3.0/24"
}

module "mysql" {
  source = "../../modules/mysql"

  compartment_id      = oci_identity_compartment.this.id
  availability_domain = local.availability_domain
  subnet_id           = module.network.db_subnet_id
  tags                = local.common_tags

  admin_password = random_password.db_admin.result
}

module "app_vm" {
  source = "../../modules/compute-app"

  compartment_id      = oci_identity_compartment.this.id
  availability_domain = local.availability_domain
  subnet_id           = module.network.app_subnet_id
  tags                = local.common_tags

  ocpus                   = var.app_ocpus
  memory_in_gbs           = var.app_memory_gbs
  boot_volume_size_gbs    = var.app_boot_volume_size_gbs
  boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb

  ssh_authorized_keys = var.app_ssh_public_keys

  db_host           = module.mysql.hostname
  db_admin_user     = module.mysql.admin_username
  db_admin_password = random_password.db_admin.result
  db_app_user       = var.app_db_user
  db_app_password   = random_password.db_app.result
  db_name           = var.app_db_name

  depends_on = [module.network]
}

module "watcher_vm" {
  count = var.watcher_enabled ? 1 : 0

  source = "../../modules/compute-watcher"

  compartment_id      = oci_identity_compartment.this.id
  availability_domain = local.availability_domain
  subnet_id           = module.network.watcher_subnet_id
  tags                = local.common_tags

  boot_volume_size_gbs    = var.watcher_boot_volume_size_gbs
  boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb

  ssh_authorized_keys = var.watcher_ssh_public_keys

  depends_on = [module.network]
}

module "objectstore" {
  source = "../../modules/objectstore"

  compartment_id = oci_identity_compartment.this.id
  user_id        = var.iam_user_ocid
  tags           = local.common_tags

  bucket_name = var.media_bucket_name
}

module "registry" {
  source = "../../modules/registry"

  compartment_id = oci_identity_compartment.this.id
  user_id        = var.iam_user_ocid
  user_name      = var.iam_username
  tags           = local.common_tags

  repository_name   = var.ocir_repository_name
  registry_endpoint = var.ocir_registry
  image_tag         = var.app_image_tag
}

# Rendered production .env: every infra-owned value is filled from real
# resource attributes; application secrets stay as placeholders.
resource "local_sensitive_file" "app_env" {
  filename = "${path.module}/generated/walfa.env"
  content = templatefile("${path.module}/templates/app.env.tftpl", {
    app_image  = local.app_image
    domain     = var.domain
    acme_email = var.acme_email

    db_host     = module.mysql.hostname
    db_port     = tostring(module.mysql.port)
    db_name     = var.app_db_name
    db_user     = var.app_db_user
    db_password = random_password.db_app.result

    s3_endpoint   = local.s3_endpoint
    s3_bucket     = module.objectstore.bucket_name
    s3_access_key = module.objectstore.access_key
    s3_secret_key = module.objectstore.secret_key
    region        = var.region
  })
  file_permission = "0600"
}
