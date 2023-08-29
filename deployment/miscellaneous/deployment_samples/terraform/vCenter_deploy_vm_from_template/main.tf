provider "vsphere" {
    vsphere_server       = "${var.vsphere_vcenter}"
    user                 = "${var.vsphere_user}"
    password             = "${var.vsphere_password}"
    allow_unverified_ssl = true
}

##==============================================================================
## Build VM
##==============================================================================
data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_cluster}/Resources"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "mgmt_lan" {
  name          = "${var.vsphere_vswitch_mgmt}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "test_lan" {
  name          = "${var.vsphere_vswitch_test}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_src_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  count            = "${length(var.vm_name)}"
  name		         = "${lookup(var.vm_name[count.index], "hostname")}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus          = "${var.vsphere_vm_cpu_count}"
  memory            = "${var.vsphere_vm_memory_mb}"
  guest_id          = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type         = "${data.vsphere_virtual_machine.template.scsi_type}"
  nested_hv_enabled = true

  # Wait for the VMs acquire DHCP IP address (in minutes)
  wait_for_guest_net_routable = true
  wait_for_guest_net_timeout  = 10
  wait_for_guest_ip_timeout   = 10

  network_interface {
   network_id   = "${data.vsphere_network.mgmt_lan.id}"
   adapter_type = "vmxnet3"
  }

  network_interface {
   network_id   = "${data.vsphere_network.test_lan.id}"
   adapter_type = "vmxnet3"
  }

  disk {
    name             = "disk0.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }
}

output "VM_ip" {
  value = "${vsphere_virtual_machine.vm.*.guest_ip_addresses}"
}
