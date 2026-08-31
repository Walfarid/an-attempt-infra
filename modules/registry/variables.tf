variable "compartment_id" {
  description = "Compartment OCID to create the repository and auth token in."
  type        = string
}

variable "user_id" {
  description = "OCID of the IAM user the registry auth token is attached to."
  type        = string
}

variable "user_name" {
  description = "Login name of the IAM user (part of the docker login username)."
  type        = string
}

variable "tags" {
  description = "Free-form tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "repository_name" {
  description = "Name of the container repository inside the tenancy namespace."
  type        = string
  default     = "walfa-app"

  validation {
    condition     = can(regex("^[a-z0-9_][a-z0-9_./-]*$", var.repository_name))
    error_message = "Repository name must be lowercase letters, numbers, dots, slashes, underscores or hyphens."
  }
}

variable "registry_endpoint" {
  description = "Regional OCIR endpoint used for docker login."
  type        = string
  default     = "sin.ocir.io"
}

variable "image_tag" {
  description = "Tag referenced when composing the full image path output."
  type        = string
  default     = "latest"
}

variable "auth_token_description" {
  description = "Description stored on the generated auth token."
  type        = string
  default     = "GitHub Actions deploy for walfa"
}

variable "defined_tags" {
  description = "OCI defined tags applied to every tagged resource."
  type        = map(string)
}
