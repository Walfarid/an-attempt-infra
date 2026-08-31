data "oci_objectstorage_namespace" "this" {}

# Private repository; CI pushes here with the auth token below.
resource "oci_artifacts_container_repository" "app" {
  compartment_id = var.compartment_id
  display_name   = var.repository_name
  is_public      = false

  freeform_tags = merge(var.tags, { Name = var.repository_name })
  defined_tags  = var.defined_tags

  lifecycle {
    # Deleting the repository destroys all pushed images and breaks CI/CD.
    prevent_destroy = true
  }
}

# Registry password for docker login. The token value is only returned once.
resource "oci_identity_auth_token" "deploy" {
  user_id     = var.user_id
  description = var.auth_token_description

  lifecycle {
    # Recreating the token breaks CI/CD docker login until secrets are updated.
    prevent_destroy = true
  }
}
