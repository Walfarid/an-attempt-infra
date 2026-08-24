variable "compartment_id" {
  description = "Compartment OCID to create the bucket and credentials in."
  type        = string
}

variable "user_id" {
  description = "OCID of the IAM user the Customer Secret Key is attached to."
  type        = string
}

variable "tags" {
  description = "Free-form tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "Name of the media bucket exposed through the S3-compatible API."
  type        = string
  default     = "walfa-media"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-.]{2,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters of lowercase letters, numbers, dots or hyphens."
  }
}

variable "bucket_versioning" {
  description = "Whether object versioning is enabled on the media bucket."
  type        = bool
  default     = false
}

variable "credential_display_name" {
  description = "Display name of the Customer Secret Key used as the S3-compatible key pair."
  type        = string
  default     = "walfa-s3-compat"
}
