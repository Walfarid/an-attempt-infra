variable "compartment_id" {
  description = "Compartment OCID to create the DB system in."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name for the DB system."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the private database subnet."
  type        = string
}

variable "tags" {
  description = "Free-form tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "display_name" {
  description = "Display name of the DB system."
  type        = string
  default     = "walfa-mysql"
}

variable "description" {
  description = "Free-form description of the DB system."
  type        = string
  default     = "Managed MySQL for the walfa application"
}

variable "shape_name" {
  description = "Shape name. MySQL.Free is the Always Free standalone single-node shape."
  type        = string
  default     = "MySQL.Free"
}

variable "admin_username" {
  description = "Administrator username (reserved names like root/admin are rejected by OCI)."
  type        = string
  default     = "walfa_admin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{2,31}$", var.admin_username)) && !contains(["root", "admin", "mysql"], lower(var.admin_username))
    error_message = "Admin username must be 3-32 characters starting with a letter and must not be a reserved name."
  }
}

variable "admin_password" {
  description = "Administrator password. Supply a random_password value; never a literal."
  type        = string
  sensitive   = true
}
