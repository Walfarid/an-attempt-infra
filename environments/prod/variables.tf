variable "oci_profile" {
  description = "Profile name in ~/.oci/config used to authenticate the OCI provider."
  type        = string
  default     = "DEFAULT"
}

variable "region" {
  description = "Home region. Always Free resources must live here."
  type        = string
  default     = "ap-singapore-1"
}

variable "project" {
  description = "Project slug used in resource names and tags."
  type        = string
  default     = "walfa"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "Project must be 2-21 lowercase letters, numbers or hyphens starting with a letter."
  }
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging or prod."
  }
}

variable "tags" {
  description = "Extra free-form tags applied to every tagged resource."
  type        = map(string)
  default     = {}
}

variable "compartment_name" {
  description = "Name of the dedicated compartment created for this stack."
  type        = string
  default     = "walfa-prod"
}

variable "iam_user_ocid" {
  description = "OCID of your IAM user (Console > Profile icon > User settings). Owns the S3-compatible and registry credentials."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.user\\.oc1\\..+", var.iam_user_ocid))
    error_message = "iam_user_ocid must look like ocid1.user.oc1...."
  }
}

variable "iam_username" {
  description = "Login name of your IAM user (often an email); used for docker login as <namespace>/<username>."
  type        = string

  validation {
    condition     = can(regex("^[^/]+$", var.iam_username))
    error_message = "iam_username must not contain slashes; it is combined with the namespace automatically."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Source CIDRs allowed to SSH into any VM. Set this to your own addresses."
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0 && alltrue([for c in var.ssh_allowed_cidrs : can(cidrnetmask(c))])
    error_message = "ssh_allowed_cidrs must be a non-empty list of valid IPv4 CIDRs."
  }
}

variable "app_ssh_public_keys" {
  description = "SSH public keys authorized on the app VM."
  type        = list(string)

  validation {
    condition     = length(var.app_ssh_public_keys) > 0
    error_message = "At least one SSH public key is required for the app VM."
  }
}

variable "watcher_ssh_public_keys" {
  description = "SSH public keys authorized on the watcher VM."
  type        = list(string)

  validation {
    condition     = length(var.watcher_ssh_public_keys) > 0
    error_message = "At least one SSH public key is required for the watcher VM."
  }
}

variable "app_ocpus" {
  description = "OCPUs allocated to the A1 app VM from the Always Free allowance."
  type        = number
  default     = 4

  validation {
    condition     = var.app_ocpus >= 1 && var.app_ocpus <= 4
    error_message = "The Always Free A1 allowance covers at most 4 OCPUs."
  }
}

variable "app_memory_gbs" {
  description = "Memory allocated to the A1 app VM from the Always Free allowance."
  type        = number
  default     = 24

  validation {
    condition     = var.app_memory_gbs >= 6 && var.app_memory_gbs <= 24
    error_message = "The Always Free A1 allowance covers at most 24 GB of memory."
  }
}

variable "app_boot_volume_size_gbs" {
  description = "Boot volume size of the app VM (pooled 200 GB free block storage)."
  type        = number
  default     = 50

  validation {
    condition     = var.app_boot_volume_size_gbs >= 47
    error_message = "OCI requires a minimum boot volume size of 47 GB."
  }
}

variable "watcher_boot_volume_size_gbs" {
  description = "Boot volume size of the watcher VM (pooled 200 GB free block storage)."
  type        = number
  default     = 50

  validation {
    condition     = var.watcher_boot_volume_size_gbs >= 50
    error_message = "OCI requires a minimum boot volume size of 50 GB."
  }
}

variable "watcher_enabled" {
  description = "Create the watcher VM. Requires standard-e2-micro-core-count quota, which defaults to zero on PAYG tenancies - request an increase (Console > Governance > Limits) before enabling."
  type        = bool
  default     = false
}

variable "valkey_enabled" {
  description = "Create the dedicated Valkey VM (compute-valkey module). Off by default: Valkey runs on the app VM instead; flip to true to also provision the micro VM when `standard-e2-micro-core-count` quota and host capacity allow."
  type        = bool
  default     = false
}

variable "valkey_availability_domain" {
  description = "Availability domain for the Valkey VM. Empty uses the stack's default domain; set this to escape 'Out of host capacity' for the micro shape in one domain."
  type        = string
  default     = ""
}

variable "boot_volume_vpus_per_gb" {
  description = "Boot volume performance for both VMs. 10 = Balanced, 20 = Higher Performance (free-tier volumes are not billed per VPU)."
  type        = number
  default     = 20

  validation {
    condition     = var.boot_volume_vpus_per_gb % 10 == 0 && var.boot_volume_vpus_per_gb >= 0 && var.boot_volume_vpus_per_gb <= 120
    error_message = "VPUs/GB must be a multiple of 10 between 0 and 120."
  }
}

variable "media_bucket_name" {
  description = "Object Storage bucket for application media."
  type        = string
  default     = "walfa-media"
}

variable "ocir_repository_name" {
  description = "OCIR repository name for application images."
  type        = string
  default     = "walfa-app"
}

variable "ocir_registry" {
  description = "Regional OCIR endpoint."
  type        = string
  default     = "sin.ocir.io"
}

variable "app_image_tag" {
  description = "Image tag referenced in generated configuration."
  type        = string
  default     = "latest"
}

variable "app_db_name" {
  description = "Application database name created inside the managed MySQL system."
  type        = string
  default     = "walfa"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{2,31}$", var.app_db_name))
    error_message = "Database name must be 3-32 characters starting with a letter."
  }
}

variable "app_db_user" {
  description = "Application database username created inside the managed MySQL system."
  type        = string
  default     = "walfa_app"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{2,31}$", var.app_db_user))
    error_message = "Database username must be 3-32 characters starting with a letter."
  }
}

variable "domain" {
  description = "Public domain served by the app VM (used in the generated .env). Empty if not decided yet."
  type        = string
  default     = ""
}

variable "acme_email" {
  description = "Email used for ACME certificate registration (used in the generated .env)."
  type        = string
  default     = ""
}

# Application secrets rendered into the generated .env. Values ship in
# terraform.tfvars (git-ignored), never in the repo.
variable "workos_client_id" {
  description = "WorkOS (AuthKit) OAuth client ID."
  type        = string
  default     = ""
  sensitive   = true
}

variable "workos_api_key" {
  description = "WorkOS (AuthKit) API key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "turnstile_site_key" {
  description = "Cloudflare Turnstile site key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "turnstile_secret_key" {
  description = "Cloudflare Turnstile secret key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "clarity_project_id" {
  description = "Microsoft Clarity project ID for frontend analytics."
  type        = string
  default     = ""
}

variable "google_analytics_id" {
  description = "Google Analytics 4 measurement ID (G-XXXXXXX)."
  type        = string
  default     = ""
}

variable "adstxt_content" {
  description = "Content served at /ads.txt (one line per authorized seller). Empty disables the route."
  type        = string
  default     = ""
}

variable "adsense_client_id" {
  description = "Google AdSense publisher ID (ca-pub-XXXXXXXXXXXXXXXX). Empty disables the AdSense script."
  type        = string
  default     = ""
}

variable "ezoic_enabled" {
  description = "Enable Ezoic ads on the single-post page. Turns on the header scripts, the post-page ad slot, and the /ads.txt 301 redirect."
  type        = bool
  default     = false
}

variable "ezoic_placeholder_id" {
  description = "Ezoic placeholder ID from the dashboard (EzoicAds → Ad Locations → Placeholders). Must match the placement it belongs to."
  type        = string
  default     = ""
}

variable "ezoic_adstxt_manager_id" {
  description = "Ezoic ads.txt manager ID. Used by the /ads.txt 301 redirect route."
  type        = string
  default     = "19390"
}

variable "app_key" {
  description = "Laravel APP_KEY. Must be preserved across deploys to avoid invalidating encrypted cookies/sessions."
  type        = string
  sensitive   = true
}
