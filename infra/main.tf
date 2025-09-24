terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid != "" ? var.tenancy_ocid : null
  user_ocid        = var.user_ocid != "" ? var.user_ocid : null
  fingerprint      = var.fingerprint != "" ? var.fingerprint : null
  private_key_path = var.private_key_path != "" ? var.private_key_path : null
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

locals {
  ad_name = data.oci_identity_availability_domains.ads.availability_domains[var.ad_index].name
}

resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "dev-workstation-vcn"
  freeform_tags  = var.tags
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "dev-workstation-igw"
  enabled        = true
}

resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "dev-workstation-rt"
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "dev-workstation-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  # RDP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 3389
      max = 3389
    }
  }
  # ICMP unreachable
  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "public" {
  cidr_block        = var.public_subnet_cidr
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  display_name      = "dev-workstation-public"
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.sl.id]
  dns_label         = "pub" 
  prohibit_public_ip_on_vnic = false
}

data "oci_core_images" "ol9_aarch64" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  filter {
    name   = "platform"
    values = ["linux"]
  }
}

resource "random_password" "rdp_password" {
  length           = 16
  special          = false
  override_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

locals {
  ssh_key_block = var.ssh_public_key != "" ? "ssh_authorized_keys:\n      - ${var.ssh_public_key}" : ""

  cloud_init = templatefile("${path.module}/cloud-init.yaml.tmpl", {
    ssh_key_block = local.ssh_key_block
    rdp_password  = random_password.rdp_password.result
  })
}

resource "oci_core_instance" "dev" {
  availability_domain = local.ad_name
  compartment_id      = var.compartment_ocid
  display_name        = var.display_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.public.id
    display_name     = "${var.display_name}-vnic"
    hostname_label   = replace(var.display_name, "_", "-")
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ol9_aarch64.images[0].id
    boot_volume_size_in_gbs = 100
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }

  freeform_tags = var.tags
}

# Lookup primary VNIC to get public IP
data "oci_core_vnic_attachments" "att" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.dev.id
}

data "oci_core_vnic" "primary" {
  vnic_id = data.oci_core_vnic_attachments.att.vnic_attachments[0].vnic_id
}

output "public_ip" {
  value       = data.oci_core_vnic.primary.public_ip_address
  description = "Public IP of the workstation"
}
