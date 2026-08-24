locals {
  user_data_b64 = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {}))
}

# Newest Ubuntu x86_64 platform image matching the requested OS version.
data "oci_core_images" "watcher" {
  compartment_id           = var.compartment_id
  operating_system         = var.image_os
  operating_system_version = var.image_os_version
  shape                    = var.shape

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "watcher" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.display_name

  shape = var.shape

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.watcher.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
  }

  create_vnic_details {
    # Ephemeral public IP: the watcher only needs outbound access plus SSH.
    subnet_id        = var.subnet_id
    assign_public_ip = true
    hostname_label   = var.hostname_label
    display_name     = "${var.display_name}-vnic"
  }

  metadata = {
    ssh_authorized_keys = join("\n", var.ssh_authorized_keys)
    user_data           = local.user_data_b64
  }

  freeform_tags = merge(var.tags, { Name = var.display_name })

  lifecycle {
    ignore_changes = [metadata["user_data"]]
  }
}
