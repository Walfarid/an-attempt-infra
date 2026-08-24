variable "oci_profile" {
  description = "Profile name in ~/.oci/config used to authenticate the OCI provider."
  type        = string
  default     = "DEFAULT"
}

variable "compartment_id" {
  description = "Compartment OCID for the state bucket - your tenancy/root OCID works fine for a one-time bootstrap."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.compartment\\.oc1\\..+|^ocid1\\.tenancy\\.oc1\\..+", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment.oc1... / ocid1.tenancy.oc1...)"
  }
}

variable "user_ocid" {
  description = "OCID of your IAM user (Console > Profile icon > User settings) that will own the backend Customer Secret Key."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.user\\.oc1\\..+", var.user_ocid))
    error_message = "user_ocid must look like ocid1.user.oc1...."
  }
}

variable "state_bucket_name" {
  description = "Name of the Object Storage bucket holding Terraform state files."
  type        = string
  default     = "walfa-tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-.]{2,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be 3-63 characters of lowercase letters, numbers, dots or hyphens."
  }
}

variable "credential_display_name" {
  description = "Display name for the Customer Secret Key created for the S3-compatible state backend."
  type        = string
  default     = "terraform-state-backend"
}
