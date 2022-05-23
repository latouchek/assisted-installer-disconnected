resource "libvirt_network" "machine_network" {
  name = "machine-net"
  mode = "nat"
  autostart = true
  addresses = ["10.42.169.96/27"]
  bridge = "br7"
  dhcp {
        enabled = false
        }  
}
