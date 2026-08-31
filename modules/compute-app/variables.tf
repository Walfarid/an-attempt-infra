variable "compartment_id" {
  description = "Compartment OCID to create the instance in."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name to launch the instance in."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the public application subnet."
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
  description = "Display name of the instance and its reserved public IP."
  type        = string
  default     = "walfa-app"
}

variable "hostname_label" {
  description = "DNS hostname label for the VNIC (must be unique within the VCN)."
  type        = string
  default     = "walfa-app"
}

variable "shape" {
  description = "Compute shape. VM.Standard.A1.Flex is the Ampere ARM shape."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs allocated from the Always Free A1 allowance."
  type        = number
  default     = 4

  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 4
    error_message = "The Always Free A1 allowance covers at most 4 OCPUs."
  }
}

variable "memory_in_gbs" {
  description = "Memory in GB allocated from the Always Free A1 allowance."
  type        = number
  default     = 24

  validation {
    condition     = var.memory_in_gbs >= 6 && var.memory_in_gbs <= 24
    error_message = "The Always Free A1 allowance covers at most 24 GB of memory."
  }
}

variable "boot_volume_size_gbs" {
  description = "Boot volume size in GB (counts against the pooled 200 GB free block storage)."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gbs >= 47
    error_message = "OCI requires a minimum boot volume size of 47 GB."
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

variable "db_host" {
  description = "Hostname of the managed MySQL DB system."
  type        = string
}

variable "db_port" {
  description = "Port of the managed MySQL DB system."
  type        = number
  default     = 3306
}

variable "db_admin_user" {
  description = "Administrator username of the managed MySQL DB system."
  type        = string
}

variable "db_admin_password" {
  description = "Administrator password of the managed MySQL DB system."
  type        = string
  sensitive   = true
}

variable "db_app_user" {
  description = "Application database username created by the bootstrap script."
  type        = string
}

variable "db_app_password" {
  description = "Application database user password created by the bootstrap script."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the application database created by the bootstrap script."
  type        = string
}

variable "ca_bundle_url" {
  description = "Optional URL of the MySQL HeatWave CA bundle fetched onto the VM. Leave empty to install the bundle manually after apply."
  type        = string
  default     = ""
}
