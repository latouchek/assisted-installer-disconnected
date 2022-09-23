# variable "openstack_user_name" {}
# variable "openstack_tenant_name" {}
# variable "openstack_password" {}
# variable "openstack_auth_url" {}

variable "namemaster" {
   type = list(string)
   default = ["ocp4-master0", "ocp4-master1","ocp4-master2"]
 }

variable "ipmaster" {
   type = list(string)
   default = ["10.254.140.20", "10.254.140.21","10.254.140.22"]
 }


variable "nameworker" {
    type = list(string)
    default = ["ocp4-worker0", "ocp4-worker1","ocp4-worker2"]
}
variable "ipworker" {
    type = list(string)
    default = ["10.254.140.23", "10.254.140.24","10.254.140.25"]
}


variable "ssh_key_pair" {
  default = "kl"
}

variable "availability_zone" {
	default = "nova"
}

variable "security_group" {
	default = "default"
}
variable "masterflavor" {
	default = "ocp.master"
}
variable "workerflavor" {
	default = "ocp.master"
}
variable "network" {
	default  = "nmnet-103"
}
