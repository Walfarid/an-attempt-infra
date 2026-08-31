variable "name_prefix" {
  description = "Prefix used for all network resource names."
  type        = string
  default     = "walfa"
}

variable "compartment_id" {
  description = "Compartment OCID to create the network in."
  type        = string
}

variable "tags" {
  description = "Free-form tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "vcn_cidr" {
  description = "CIDR block of the VCN."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vcn_cidr))
    error_message = "vcn_cidr must be a valid IPv4 CIDR."
  }
}

variable "app_subnet_cidr" {
  description = "CIDR of the public application subnet."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.app_subnet_cidr))
    error_message = "app_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "db_subnet_cidr" {
  description = "CIDR of the private database subnet."
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.db_subnet_cidr))
    error_message = "db_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "watcher_subnet_cidr" {
  description = "CIDR of the public watcher (Uptime-Kuma) subnet."
  type        = string
  default     = "10.0.3.0/24"

  validation {
    condition     = can(cidrnetmask(var.watcher_subnet_cidr))
    error_message = "watcher_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Source CIDRs allowed to reach SSH (port 22) on any VM. Restrict this to your own addresses."
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0 && alltrue([for c in var.ssh_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "ssh_allowed_cidrs must be a non-empty list of valid IPv4 CIDRs."
  }
}

variable "valkey_subnet_cidr" {
  description = "CIDR of the private Valkey subnet."
  type        = string
  default     = "10.0.4.0/24"

  validation {
    condition     = can(cidrnetmask(var.valkey_subnet_cidr))
    error_message = "valkey_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "defined_tags" {
  description = "OCI defined tags applied to every tagged resource."
  type        = map(string)
  default     = {}
}
