# State lives in OCI Object Storage using the native OCI backend (Terraform >= 1.12).
#
# Bucket, key and namespace are supplied per environment with:
#   terraform init -backend-config=backend.config.hcl
# Credentials come from the OCI config file (~/.oci/config) via config_file_profile.
#
# The OCI backend supports state locking natively.
terraform {
  backend "oci" {
    config_file_profile = "DEFAULT"
  }
}
