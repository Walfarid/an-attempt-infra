output "state_bucket_name" {
  description = "Name of the Terraform state bucket."
  value       = oci_objectstorage_bucket.tfstate.name
}

output "namespace" {
  description = "Tenancy Object Storage namespace (used in the S3-compat endpoint)."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "access_key" {
  description = "Access key portion of the Customer Secret Key (AWS_ACCESS_KEY_ID for the backend)."
  value       = oci_identity_customer_secret_key.tf_backend.id
}

output "secret_key" {
  description = "Secret portion of the Customer Secret Key (AWS_SECRET_ACCESS_KEY for the backend)."
  value       = oci_identity_customer_secret_key.tf_backend.key
  sensitive   = true
}

output "next_steps" {
  description = "What to do with these outputs."
  value       = "export AWS_ACCESS_KEY_ID='<access_key>' AWS_SECRET_ACCESS_KEY='<secret_key>' then run: terraform init -backend-config=environments/prod/backend.config.hcl"
}
