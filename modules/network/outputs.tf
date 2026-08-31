output "vcn_id" {
  description = "OCID of the VCN."
  value       = oci_core_vcn.this.id
}

output "app_subnet_id" {
  description = "OCID of the public application subnet."
  value       = oci_core_subnet.app_public.id
}

output "app_subnet_cidr" {
  description = "CIDR of the public application subnet (used as MySQL ingress source)."
  value       = oci_core_subnet.app_public.cidr_block
}

output "watcher_subnet_id" {
  description = "OCID of the public watcher subnet."
  value       = oci_core_subnet.watcher_public.id
}

output "db_subnet_id" {
  description = "OCID of the private database subnet."
  value       = oci_core_subnet.db_private.id
}

output "valkey_subnet_id" {
  description = "OCID of the private Valkey subnet."
  value       = oci_core_subnet.valkey_private.id
}
