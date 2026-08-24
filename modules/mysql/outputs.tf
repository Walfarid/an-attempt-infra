output "hostname" {
  description = "Private hostname to connect to (resolves inside the VCN)."
  value       = one(oci_mysql_mysql_db_system.this.endpoints).hostname
}

output "ip_address" {
  description = "Private IP of the DB system."
  value       = one(oci_mysql_mysql_db_system.this.endpoints).ip_address
}

output "port" {
  description = "MySQL listener port."
  value       = one(oci_mysql_mysql_db_system.this.endpoints).port
}

output "admin_username" {
  description = "Administrator username."
  value       = var.admin_username
}

output "shape_name" {
  description = "Provisioned shape name."
  value       = oci_mysql_mysql_db_system.this.shape_name
}
