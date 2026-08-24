output "instance_id" {
  description = "OCID of the application instance."
  value       = oci_core_instance.app.id
}

output "public_ip" {
  description = "Reserved public IP attached to the instance."
  value       = oci_core_public_ip.app.ip_address
}

output "private_ip" {
  description = "Private IP of the instance inside the VCN."
  value       = oci_core_instance.app.private_ip
}

output "image_ocid" {
  description = "OCID of the Ubuntu image the instance was launched from."
  value       = oci_core_instance.app.source_details[0].source_id
}
