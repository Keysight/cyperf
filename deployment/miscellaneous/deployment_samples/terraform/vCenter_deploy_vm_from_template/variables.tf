variable "vsphere_vcenter" {}
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_datacenter" {}
variable "vsphere_cluster" {}
variable "vsphere_datastore" {}
variable "vsphere_src_template" {}
variable "vsphere_vswitch_mgmt" {}
variable "vsphere_vswitch_test" {}
variable "vsphere_vm_cpu_count" {}
variable "vsphere_vm_memory_mb" {}
variable "vm_name" {
   type = "list"
   default = [ ] 	
}
