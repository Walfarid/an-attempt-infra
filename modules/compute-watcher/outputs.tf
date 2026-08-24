output "instance_id" {
  description = "OCID of the watcher instance."
  value       = oci_core_instance.watcher.id
}

output "public_ip" {
  description = "Public IP of the watcher instance (ephemeral)."
  value       = oci_core_instance.watcher.public_ip
}

output "private_ip" {
  description = "Private IP of the watcher instance inside the VCN."
  value       = oci_core_instance.watcher.private_ip
}

output "image_ocid" {
  description = "OCID of the Ubuntu image the instance was launched from."
  value       = oci_core_instance.watcher.source_details[0].source_id
}
