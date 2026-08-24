# State lives in OCI Object Storage through the S3-compatible API.
#
# Bucket, key and endpoint are supplied per environment with:
#   terraform init -backend-config=backend.config.hcl
# Credentials come from the bootstrap stack outputs via:
#   export AWS_ACCESS_KEY_ID=<access_key> AWS_SECRET_ACCESS_KEY=<secret_key>
#
# Note: OCI's S3 compatibility layer does not support state locking, so never
# run two applies against this backend at the same time.
terraform {
  backend "s3" {
    region                      = "ap-singapore-1"
    force_path_style            = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true

    # Terraform >= 1.11 sends CRC32C checksums that OCI's S3 layer rejects.
    skip_s3_checksum = true
  }
}
