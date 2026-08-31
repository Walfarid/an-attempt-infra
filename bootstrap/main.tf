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

  lifecycle {
    # Losing the state bucket means losing all Terraform state for prod.
    prevent_destroy = true
  }
}

# S3-compatible key pair used by the Terraform S3 backend. The secret portion
# is only returned once at creation time.
resource "oci_identity_customer_secret_key" "tf_backend" {
  user_id      = var.user_ocid
  display_name = var.credential_display_name

  lifecycle {
    # Recreating the key invalidates the S3 backend credentials.
    prevent_destroy = true
  }
}
