provider "google" {
  credentials = file(var.gcp_credential_file)
  project     = var.gcp_project_name
  region      = var.gcp_region_name
  zone        = var.gcp_zone_name
}

locals {
  gcp_project_name                 = var.gcp_project_name
  gcp_region_name                  = var.gcp_region_name
  gcp_zone_name                    = var.gcp_zone_name
  gcp_deployment                   = var.gcp_deployment
  gcp_owner                        = replace(split(":", split("/", var.gcp_owner)[2])[0], ".", "-")
  gcp_project_tag                  = var.gcp_project_tag
  gcp_mgmt_test_subnet             = var.gcp_agent_mgmt_test_subnet
  gcp_controller_ip                = var.gcp_controller_ip
  gcp_options_tag                  = "MANUAL"
  gcp_allowed_cidr                 = ["0.0.0.0/0"]
  gcp_mgmt_subnet_name                = join("/", ["projects", var.gcp_project_name, "regions", var.gcp_region_name,  "subnetworks", var.gcp_agent_mgmt_test_subnet])     
  #subnetwork = "projects/your-gcp-project-id/regions/us-central1/subnetworks/your-subnet-name"
  gcp_agent_machine_type              = var.gcp_agent_machine_type
  gcp_client_instance_name            = join("-", ["client", var.agent_version])
  gcp_agent_serial_port_enable        = "true"
  gcp_agent_can_ip_forward            = "false"
  gcp_ssh_key                         = var.gcp_ssh_key
}


resource "google_compute_resource_policy" "gcp_placement_group" {
  name   = "${local.gcp_deployment}-agent-deployment-policy"
  region = local.gcp_region_name
  group_placement_policy {
    vm_count    = var.gcp_agent_number * 2
    collocation = "COLLOCATED"
  }
}

resource "google_compute_instance" "gcp_client_agent_instance" {
  count                     = var.gcp_agent_number
  name                      = length("${local.gcp_deployment}-${local.gcp_client_instance_name}-${count.index}") < 63 ? "${local.gcp_deployment}-${local.gcp_client_instance_name}-${count.index}" : "${local.gcp_deployment}-client-${split("tiger-", "${local.gcp_client_instance_name}")[1]}-${count.index}"
  can_ip_forward            = local.gcp_agent_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_agent_machine_type
  allow_stopping_for_update = true
  resource_policies         = [google_compute_resource_policy.gcp_placement_group.self_link]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/kt-nas-cyperf-dev/global/images/${var.agent_version}"
    }
  }
  tags = ["gcp-cyperf-agents"]
  network_interface {
    subnetwork = local.gcp_mgmt_subnet_name
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo rm -rf /etc/portmanager/node_id.txt
    cyperfagent feature allow_mgmt_iface_for_test enable
    sudo cyperfagent controller set ${var.gcp_controller_ip} --skip-restart
    sudo cyperfagent configuration reload
  EOF
  metadata = {
    Owner              = local.gcp_owner
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }
  labels = {
    owner   = local.gcp_owner
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

