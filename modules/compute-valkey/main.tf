locals {
  # The Valkey password is injected via base64-encoded env file.
  valkey_env_b64 = base64encode(templatefile("${path.module}/templates/valkey.env.tftpl", {
    valkey_password = var.valkey_password
  }))

  bootstrap_script_b64 = base64encode(file("${path.module}/scripts/bootstrap-valkey.sh"))

  user_data_b64 = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    valkey_env_b64      = local.valkey_env_b64
    bootstrap_script_b64 = local.bootstrap_script_b64
  }))
}

# Newest Ubuntu x86_64 platform image matching the requested OS version.
data "oci_core_images" "valkey" {
  compartment_id           = var.compartment_id
  operating_system         = var.image_os
  operating_system_version = var.image_os_version
  shape                    = var.shape

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "valkey" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.display_name

  shape = var.shape

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.valkey.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    hostname_label   = var.hostname_label
    display_name     = "${var.display_name}-vnic"
  }

  metadata = {
    ssh_authorized_keys = join("\n", var.ssh_authorized_keys)
    user_data           = local.user_data_b64
  }

  freeform_tags = merge(var.tags, { Name = var.display_name })
  defined_tags  = var.defined_tags

  lifecycle {
    ignore_changes = [
      metadata["user_data"],
      metadata["ssh_authorized_keys"],
    ]
    prevent_destroy = true
  }
}

# Data sources to retrieve the private IP (following compute-app pattern).
data "oci_core_vnic_attachments" "valkey" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.valkey.id
}

data "oci_core_private_ips" "valkey" {
  vnic_id = data.oci_core_vnic_attachments.valkey.vnic_attachments[0].vnic_id
}