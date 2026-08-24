output "namespace" {
  description = "Tenancy Object Storage namespace."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "bucket_name" {
  description = "Name of the media bucket."
  value       = oci_objectstorage_bucket.media.name
}

output "access_key" {
  description = "Access key portion of the S3-compatible credentials."
  value       = oci_identity_customer_secret_key.s3.id
}

output "secret_key" {
  description = "Secret portion of the S3-compatible credentials."
  value       = oci_identity_customer_secret_key.s3.key
  sensitive   = true
}
