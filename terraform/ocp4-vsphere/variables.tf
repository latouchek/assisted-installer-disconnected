

variable "namemaster" {
   type = list(string)
   default = ["ocp4-master0", "ocp4-master1","ocp4-master2"]
 }
variable "nameworker" {
    type = list(string)
    default = ["ocp4-worker0", "ocp4-worker1","ocp4-worker2"]
}



variable "host-master-mem" {
  type = string
  default = "32000"
}
variable "host-worker-mem" {
  type = string
  default = "96000"
}
variable "host-master-cores" {
  type = string
  default = "4"
}
variable "host-worker-cores" {
  type = string
  default = "2"
}
