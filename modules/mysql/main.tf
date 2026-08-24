resource "oci_mysql_mysql_db_system" "this" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  subnet_id           = var.subnet_id
  display_name        = var.display_name
  description         = var.description

  # MySQL.Free: Always Free standalone single-node system with fixed 50 GB
  # storage, fixed one-day backups and no HA or read replicas.
  shape_name     = var.shape_name
  admin_username = var.admin_username
  admin_password = var.admin_password
  port           = 3306

  freeform_tags = merge(var.tags, { Name = var.display_name })

  lifecycle {
    # Password rotation happens out-of-band (console/SQL); do not churn state.
    ignore_changes = [admin_password]
  }
}
