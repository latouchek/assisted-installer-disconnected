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

provider "nutanix" {
  username     = "admin"
  password     = "nx2Tech123!"
  endpoint     = "10.42.169.37"
  insecure     = true
  wait_timeout = 60
}
resource "nutanix_image" "bastion-image" {
  name        = "bastion-image"
  description = "Centos  Stream 8 qcow2 cloud image"
  source_uri  = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20201019.1.x86_64.qcow2"
}


resource "nutanix_virtual_machine" "bastion" {
  name   = "bastion"
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = "2"
  num_sockets          = "2"
  memory_size_mib      = "16000"
  boot_device_order_list = ["DISK", "CDROM"]
  guest_customization_cloud_init_user_data ="${base64encode("${file("cloud-init")}")}"
  # guest_customization_cloud_init_meta_data ="${base64encode("${file("network-config")}")}"
  disk_list {
    disk_size_bytes = 120 * 1024 * 1024 * 1024
    data_source_reference = {
      kind = "image"
      uuid = nutanix_image.bastion-image.id
    }
  }

  disk_list {
    disk_size_bytes = 1200 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "1"
      }
    }
  }
  disk_list {
    disk_size_bytes = 2000 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "2"
      }
    }
  }
 nic_list { 
    subnet_uuid = data.nutanix_subnet.subnet.id
  }
}
