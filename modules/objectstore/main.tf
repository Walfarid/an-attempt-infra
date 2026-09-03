data "oci_objectstorage_namespace" "this" {}

resource "oci_objectstorage_bucket" "media" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.bucket_name

  access_type  = "ObjectRead"
  storage_tier = "Standard"
  versioning   = var.bucket_versioning ? "Enabled" : "Disabled"

  freeform_tags = merge(var.tags, { Name = var.bucket_name })
  defined_tags  = var.defined_tags

  lifecycle {
    # Bucket holds application media; accidental deletion is unrecoverable.
    prevent_destroy = true
  }
}

# AWS-style key pair for the S3-compatible endpoint. The secret is shown only
# at creation time, so it is exported as a sensitive output for the .env file.
resource "oci_identity_customer_secret_key" "s3" {
  user_id      = var.user_id
  display_name = var.credential_display_name

  lifecycle {
    # Recreating the key invalidates S3-compatible credentials used by the app.
    prevent_destroy = true
  }
}
