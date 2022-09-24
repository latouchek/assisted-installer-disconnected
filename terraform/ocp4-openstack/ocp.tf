terraform {
  required_version = ">= 1.0.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}
provider "openstack" {
  user_name = ""
  tenant_name = "TDS-IPERF01"
  password  = ""
  auth_url  = "https://10.254.136.132:13000"
  domain_name = "mydomain"
  use_octavia = "true"
  insecure = "true"
}

resource "openstack_images_image_v2" "discovery-iso" {
  name = "discovery-iso"
  local_file_path = "/opt/discovery_image_ocpd.iso"
  container_format = "bare"
  disk_format      = "iso"
}


resource "openstack_compute_instance_v2" "ocpworkerVM" {
  image_name = "discovery-iso"
  name = "${element(var.nameworker, count.index)}"
  flavor_name = "${var.workerflavor}"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
  # boot device
  block_device {
    source_type           = "blank"
    volume_size           = "150"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
    disk_bus = "scsi"
  }

  # cd-rom
  block_device {
    uuid             = openstack_images_image_v2.discovery-iso.id
    source_type      = "image"
    destination_type = "volume"
    boot_index       = 1
    volume_size      = 1
    device_type      = "cdrom"
  }
  network {
    name = "${var.network}"
    fixed_ip_v4 = "${element(var.ipworker, count.index)}"
  }
  count = "${length(var.nameworker)}"
  depends_on = [openstack_compute_instance_v2.ocpmasterVM]
}
resource "openstack_compute_instance_v2" "ocpmasterVM" {
  image_name = "discovery-iso"
  name = "${element(var.namemaster, count.index)}"
  flavor_name = "${var.masterflavor}"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
    # boot device
  block_device {
    source_type           = "blank"
    volume_size           = "150"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
    disk_bus = "scsi"
  }

  # cd-rom
  block_device {
    uuid             = openstack_images_image_v2.discovery-iso.id
    source_type      = "image"
    destination_type = "volume"
    boot_index       = 1
    volume_size      = 1
    device_type      = "cdrom"
  }

  network {
    name = "${var.network}"
    fixed_ip_v4 = "${element(var.ipmaster, count.index)}"
  }
depends_on = [openstack_images_image_v2.discovery-iso]
  count = "${length(var.namemaster)}"
}
