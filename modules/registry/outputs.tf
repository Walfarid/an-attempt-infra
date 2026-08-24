output "namespace" {
  description = "Tenancy container registry namespace."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "registry_endpoint" {
  description = "OCIR endpoint for docker login."
  value       = var.registry_endpoint
}

output "login_username" {
  description = "Username for docker login (namespace/user format)."
  value       = "${data.oci_objectstorage_namespace.this.namespace}/${var.user_name}"
}

output "auth_token" {
  description = "Password for docker login. Store as the OCIR_AUTH_TOKEN GitHub secret."
  value       = oci_identity_auth_token.deploy.token
  sensitive   = true
}

output "repository_path" {
  description = "Full repository path without registry endpoint."
  value       = "${data.oci_objectstorage_namespace.this.namespace}/${var.repository_name}"
}

output "image_path" {
  description = "Full image reference to build and push from CI."
  value       = "${var.registry_endpoint}/${data.oci_objectstorage_namespace.this.namespace}/${var.repository_name}:${var.image_tag}"
}
