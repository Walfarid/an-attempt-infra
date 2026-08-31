output "instance_id" {
  description = "OCID of the Valkey instance."
  value       = oci_core_instance.valkey.id
}

output "private_ip" {
  description = "Private IP of the Valkey instance inside the VCN."
  value       = data.oci_core_private_ips.valkey.private_ips[0].ip_address
}

output "image_ocid" {
  description = "OCID of the Ubuntu image the instance was launched from."
  value       = oci_core_instance.valkey.source_details[0].source_id
}