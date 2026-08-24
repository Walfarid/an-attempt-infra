data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "tfstate" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.state_bucket_name

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"
  versioning   = "Enabled"

  freeform_tags = {
    ManagedBy = "terraform"
    Purpose   = "terraform-state"
  }
}

# S3-compatible key pair used by the Terraform S3 backend. The secret portion
# is only returned once at creation time.
resource "oci_identity_customer_secret_key" "tf_backend" {
  user_id      = var.user_ocid
  display_name = var.credential_display_name
}
