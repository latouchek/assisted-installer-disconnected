provider "vsphere" {
 user           = "administrator@vsphere.local"
 password       = "passwd"
 vsphere_server = "192.168.8.30"
 allow_unverified_ssl = true
}

# Data Sources
data "vsphere_datacenter" "dc" {
 name = "Datacenter"
}
data "vsphere_resource_pool" "pool" {
 # If you haven't resource pool, put "Resources" after cluster name
 name          = "tmobile/Resources"
 datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "datastore" {
 name          = "vsanDatastore"
 datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
 name          = "tmobile"
 datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
 name          = "VM Network"
 #name          = ""
 datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

 resource "vsphere_folder" "ocp" {
  path          = "OCP-POC"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
 }

 ###Masters#####
 resource "vsphere_virtual_machine" "master" {
   name   = "${element(var.namemaster, count.index)}"
   resource_pool_id = data.vsphere_resource_pool.pool.id
   datastore_id     = data.vsphere_datastore.datastore.id
   folder = "OCP-POC"
   num_cpus = 8
   memory   = var.host-master-mem
   guest_id = "rhel8_64Guest"
   wait_for_guest_net_timeout = "0"
   enable_disk_uuid  = true
   # firmware = "bios"

   network_interface {
     network_id = data.vsphere_network.network.id
     use_static_mac = true
     mac_address = "AA:BB:CC:11:42:1${count.index}"
   }
  #  network_interface {
  #    network_id = data.vsphere_network.network.id
  #    use_static_mac = true
  #    mac_address = "AA:BB:CC:11:42:c${count.index}"
  #  }
  #  network_interface {
  #    network_id = data.vsphere_network.network.id
  #    use_static_mac = true
  #    mac_address = "AA:BB:CC:11:42:d${count.index}"
  #  }
   cdrom {
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path         = "ISO/discovery_image_ocpd.iso"
   }
   disk {
     label = "bootdisk.${element(var.namemaster, count.index)}"
     #name   = "bootdisk.${element(var.namemaster, count.index)}.vmdk"
     size  = 120
   }
   count = "${length(var.namemaster)}"
   depends_on = [vsphere_folder.ocp]
 }
####workers#####
 resource "vsphere_virtual_machine" "worker" {
   name   = "${element(var.nameworker, count.index)}"
   resource_pool_id = data.vsphere_resource_pool.pool.id
   datastore_id     = data.vsphere_datastore.datastore.id
   folder = "OCP-POC"
   num_cpus = 16
   memory   = var.host-worker-mem
   guest_id = "rhel8_64Guest"
   wait_for_guest_net_timeout = "0"
   enable_disk_uuid  = true
   nested_hv_enabled = true
   # firmware = "bios"
   network_interface {
     network_id = data.vsphere_network.network.id
     use_static_mac = true
     mac_address = "AA:BB:CC:11:42:2${count.index}"
   }
    network_interface {
      network_id = data.vsphere_network.network.id
      use_static_mac = true
      mac_address = "AA:BB:CC:11:42:5${count.index}"
    }
  #  network_interface {
  #    network_id = data.vsphere_network.network.id
  #    use_static_mac = true
  #    mac_address = "AA:BB:CC:11:42:6${count.index}"
  #  }  
   cdrom {
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    path         = "ISO/discovery_image_ocpd.iso"
   }
   disk {
     label = "bootdisk.${element(var.nameworker, count.index)}"
     size  = 120
   }
   disk {
     label = "mon.${element(var.nameworker, count.index)}"
     # name   = "mon.${element(var.nameworker, count.index)}.vmdk"
     size  = 300
     unit_number = 1
   }
   disk {
     label = "osd1.${element(var.nameworker, count.index)}"
     # name   = "osd1.${element(var.nameworker, count.index)}.vmdk"
     size  =300
     unit_number = 2
   }
   count = "${length(var.nameworker)}"
   depends_on = [vsphere_folder.ocp]
 }
