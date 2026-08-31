locals {
  tcp_protocol = "6"
  udp_protocol = "17"
  all_protocol = "all"
}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = "${substr(var.name_prefix, 0, 11)}vcn"

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-vcn" })
  defined_tags  = var.defined_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-igw"
  enabled        = true

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
  defined_tags  = var.defined_tags
}

# Public subnets (app VM + watcher) get a default route through the IGW.
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
    description       = "Default route to the internet"
  }

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
  defined_tags  = var.defined_tags
}

# The private DB subnet has no internet route on purpose; managed MySQL does not need one.
# The private Valkey subnet also has no internet route.

resource "oci_core_security_list" "app_public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-app-sl"

  ingress_security_rules {
    protocol    = local.tcp_protocol
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTP"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = local.tcp_protocol
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTPS over TCP"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = local.udp_protocol
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTP/3 over QUIC (UDP 443)"

    udp_options {
      min = 443
      max = 443
    }
  }

  # SSH must stay open to GitHub Actions runners: their IP ranges (250+
  # CIDRs, api.github.com/meta) exceed the security-list rule budget, so the
  # rule is 0.0.0.0/0 and sshd is key-only (PasswordAuthentication no).
  # Never re-lock port 22 to a single IP — deploys die with
  # `dial tcp ...:22: i/o timeout` while the firewall silently drops them.
  ingress_security_rules {
    protocol    = local.tcp_protocol
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "SSH from anywhere (GitHub Actions deploys; key-only sshd)"

    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol         = local.all_protocol
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "All outbound traffic"
  }

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-app-sl" })
  defined_tags  = var.defined_tags
}

resource "oci_core_security_list" "watcher_public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-watcher-sl"

  dynamic "ingress_security_rules" {
    for_each = var.ssh_allowed_cidrs

    content {
      protocol    = local.tcp_protocol
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      description = "SSH from allowed source (only inbound rule)"

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  egress_security_rules {
    protocol         = local.all_protocol
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Outbound traffic for monitoring checks and updates"
  }

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-watcher-sl" })
  defined_tags  = var.defined_tags
}

resource "oci_core_security_list" "db_private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-db-sl"

  ingress_security_rules {
    protocol    = local.tcp_protocol
    source      = var.app_subnet_cidr
    source_type = "CIDR_BLOCK"
    description = "MySQL from the app subnet only"

    tcp_options {
      min = 3306
      max = 3306
    }
  }

  # No egress rules: the DB system never initiates outbound connections.

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-db-sl" })
  defined_tags  = var.defined_tags
}

# Valkey private subnet: accessible only from the app subnet.
resource "oci_core_security_list" "valkey_private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name_prefix}-valkey-sl"

  ingress_security_rules {
    protocol    = local.tcp_protocol
    source      = var.app_subnet_cidr
    source_type = "CIDR_BLOCK"
    description = "Valkey from the app subnet only"

    tcp_options {
      min = 6379
      max = 6379
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.ssh_allowed_cidrs

    content {
      protocol    = local.tcp_protocol
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      description = "SSH from allowed source"

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # No egress rules: Valkey does not initiate outbound connections.

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-valkey-sl" })
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "app_public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.app_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.app_public.id]
  display_name               = "${var.name_prefix}-app-public"
  dns_label                  = "app"
  prohibit_public_ip_on_vnic = false

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-app-public" })
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "db_private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.db_subnet_cidr
  security_list_ids          = [oci_core_security_list.db_private.id]
  display_name               = "${var.name_prefix}-db-private"
  dns_label                  = "db"
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-db-private" })
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "watcher_public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.watcher_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.watcher_public.id]
  display_name               = "${var.name_prefix}-watcher-public"
  dns_label                  = "ops"
  prohibit_public_ip_on_vnic = false

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-watcher-public" })
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "valkey_private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.valkey_subnet_cidr
  security_list_ids          = [oci_core_security_list.valkey_private.id]
  display_name               = "${var.name_prefix}-valkey-private"
  dns_label                  = "valkey"
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(var.tags, { Name = "${var.name_prefix}-valkey-private" })
  defined_tags  = var.defined_tags
}
