variable "compartment_id" {
  description = "Compartment OCID to create the instance in."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name to launch the instance in."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the private Valkey subnet."
  type        = string
}

variable "tags" {
  description = "Free-form tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags applied to every tagged resource."
  type        = map(string)
  default     = {}
}

variable "display_name" {
  description = "Display name of the Valkey instance."
  type        = string
  default     = "walfa-valkey"
}

variable "hostname_label" {
  description = "DNS hostname label for the VNIC (must be unique within the VCN)."
  type        = string
  default     = "valkey"
}

variable "shape" {
  description = "Compute shape. VM.Standard.E2.1.Micro is the Always Free AMD micro shape."
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "boot_volume_size_gbs" {
  description = "Boot volume size in GB (counts against the pooled 200 GB free block storage)."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gbs >= 50
    error_message = "OCI requires a minimum boot volume size of 50 GB."
  }
}

variable "boot_volume_vpus_per_gb" {
  description = "Boot volume performance in VPUs/GB. 10 = Balanced, 20 = Higher Performance."
  type        = number
  default     = 20

  validation {
    condition     = var.boot_volume_vpus_per_gb % 10 == 0 && var.boot_volume_vpus_per_gb >= 0 && var.boot_volume_vpus_per_gb <= 120
    error_message = "VPUs/GB must be a multiple of 10 between 0 and 120."
  }
}

variable "image_os" {
  description = "Operating system name used when looking up the platform image."
  type        = string
  default     = "Canonical Ubuntu"
}

variable "image_os_version" {
  description = "Operating system version used when looking up the platform image."
  type        = string
  default     = "24.04"
}

variable "ssh_authorized_keys" {
  description = "SSH public keys authorized on the instance."
  type        = list(string)

  validation {
    condition     = length(var.ssh_authorized_keys) > 0
    error_message = "At least one SSH public key is required."
  }
}

variable "valkey_password" {
  description = "Password for Valkey requirepass directive."
  type        = string
  sensitive   = true
}