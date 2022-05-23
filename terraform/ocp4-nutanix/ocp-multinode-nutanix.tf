 terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "1.2.2"
    }
  }
}

data "nutanix_cluster" "cluster" {
  name = "PHX-POC169"
}
data "nutanix_subnet" "subnet" {
  subnet_name = "Primary"
}
variable "namemaster" {
   type = list(string)
   default = ["ocp4-master0", "ocp4-master1","ocp4-master2"]
 }
variable "nameworker" {
    type = list(string)
    default = ["ocp4-worker0", "ocp4-worker1","ocp4-worker2"]
}

provider "nutanix" {
  username     = "admin"
  password     = "passwd"
  endpoint     = "10.42.169.37"
  insecure     = true
  wait_timeout = 60
}
variable "host-master-mem" {
  type = string
  default = "24000"
}
variable "host-worker-mem" {
  type = string
  default = "32000"
}
variable "host-master-vcpus" {
  type = string
  default = "4"
}
variable "host-worker-vcpus" {
  type = string
  default = "8"
}
#####We upload the ISO the nodes will boot from #####
resource "nutanix_image" "ocpai" {
  name        = "OCP_AI_ISO"
  description = "OCP_DISCOVERY_IMAGE"
  image_type  = "ISO_IMAGE"
  source_path  = "/opt/discovery_image.iso"
}

resource "nutanix_virtual_machine" "master" {
  name   = "${element(var.namemaster, count.index)}"
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = var.host-master-vcpus
  num_sockets          = "2"
  memory_size_mib      = var.host-master-mem
  boot_device_order_list = ["DISK", "CDROM"]

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = nutanix_image.ocpai.id
    }
  }

  disk_list {
    disk_size_bytes = 120 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "1"
      }
    }
  }
  nic_list { 
    mac_address = "AA:BB:CC:11:42:1${count.index}"
    subnet_uuid = data.nutanix_subnet.subnet.id
  }
  count = "${length(var.nameworker)}"
  depends_on = [
    nutanix_image.ocpai,
  ]
}
resource "nutanix_virtual_machine" "worker" {
  name   = "${element(var.nameworker, count.index)}"
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = var.host-worker-vcpus
  num_sockets          = "2"
  memory_size_mib      = var.host-worker-mem
  boot_device_order_list = ["DISK", "CDROM"]

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = nutanix_image.ocpai.id
    }
  }

  disk_list {
    disk_size_bytes = 120 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "1"
      }
    }
  }
 disk_list {
   disk_size_bytes = 240 * 1024 * 1024 * 1024
   device_properties {
     device_type = "DISK"
     disk_address = {
       "adapter_type" = "SCSI"
       "device_index" = "2"
     }
   }
 }
 disk_list {
   disk_size_bytes = 240 * 1024 * 1024 * 1024
   device_properties {
     device_type = "DISK"
     disk_address = {
       "adapter_type" = "SCSI"
       "device_index" = "3"
     }
   }
 }
  nic_list { 
    mac_address = "AA:BB:CC:11:42:2${count.index}"
    subnet_uuid = data.nutanix_subnet.subnet.id
  }
  # nic_list { 
  #   mac_address = "AA:BB:CC:11:42:5${count.index}"
  #   subnet_uuid = data.nutanix_subnet.subnet.id
  # }
  count = "${length(var.nameworker)}"
  depends_on = [
    nutanix_image.ocpai,
  ]
}
