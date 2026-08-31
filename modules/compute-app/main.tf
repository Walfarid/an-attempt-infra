locals {
  # The bootstrap script is injected base64-encoded so cloud-init never has to
  # quote or indent shell code.
  db_bootstrap_env_b64 = base64encode(templatefile("${path.module}/templates/db-bootstrap.env.tftpl", {
    db_host        = var.db_host
    db_port        = tostring(var.db_port)
    admin_user     = var.db_admin_user
    admin_password = var.db_admin_password
    app_user       = var.db_app_user
    app_password   = var.db_app_password
    db_name        = var.db_name
    ca_bundle_url  = var.ca_bundle_url
  }))

  bootstrap_script_b64 = base64encode(file("${path.module}/scripts/bootstrap-db.sh"))

  user_data_b64 = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    db_bootstrap_env_b64 = local.db_bootstrap_env_b64
    bootstrap_script_b64 = local.bootstrap_script_b64
  }))
}

# Newest Ubuntu aarch64 platform image matching the requested OS version.
data "oci_core_images" "app" {
  compartment_id           = var.compartment_id
  operating_system         = var.image_os
  operating_system_version = var.image_os_version
  shape                    = var.shape

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "app" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.display_name

  shape = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.app.images[0].id
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

  # Re-rendering cloud-init or rotating SSH keys should not force instance
  # replacement; treat the VM as stateful and apply runtime changes manually.
  lifecycle {
    ignore_changes = [
      metadata["user_data"],
      metadata["ssh_authorized_keys"],
    ]
    prevent_destroy = true
  }
}

data "oci_core_vnic_attachments" "app" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.app.id
}

data "oci_core_private_ips" "app" {
  vnic_id = data.oci_core_vnic_attachments.app.vnic_attachments[0].vnic_id
}

# Reserved public IP: survives stop/start and instance replacement.
resource "oci_core_public_ip" "app" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "${var.display_name}-pip"
  private_ip_id  = data.oci_core_private_ips.app.private_ips[0].id

  freeform_tags = merge(var.tags, { Name = "${var.display_name}-pip" })
  defined_tags  = var.defined_tags

  lifecycle {
    # Replacement changes the public IP and breaks the Cloudflare A record.
    prevent_destroy = true
  }
}
