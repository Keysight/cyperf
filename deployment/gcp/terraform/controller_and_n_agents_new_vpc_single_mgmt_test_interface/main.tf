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
  gcp_options_tag                  = "MANUAL"
  gcp_mgmt_vpc_network_name        = "management-vpc-network"
  gcp_mgmt_subnet_name             = "management-subnet"
  gcp_mgmt_subnet_ip_range         = "172.16.6.0/24"
  gcp_allowed_cidr                 = ["0.0.0.0/0"]
  gcp_mgmt_firewall_rule_name      = "management-firewall-rule"
  gcp_mgmt_firewall_rule_name_ERG  = "management-firewall-rule-erg"
  gcp_mgmt_firewall_rule_direction = "INGRESS"
  gcp_mgmt_firewall_rule_priority  = "1000"
  gcp_mgmt_firewall_rule_PORTS = [
    "22",
    "80",
    "443"
  ]
  /*
  gcp_test_vpc_network_name        = "test-vpc-network"
  gcp_test_subnet_name             = "test-subnet"
  gcp_test_subnet_ip_range         = "10.0.0.0/8"
  gcp_test_firewall_rule_name      = "test-firewall-rule"
  gcp_test_firewall_rule_direction = "INGRESS"
  gcp_test_firewall_rule_priority  = "100"
  gcp_test_firewall_rule_source_ip_ranges = [
    "0.0.0.0/0"
  ]
  */
  gcp_mdw_instance_name               = join("", ["cyperf-", var.mdw_version])
  gcp_mdw_serial_port_enable          = "true"
  gcp_mdw_can_ip_forward              = "false"
  gcp_mdw_machine_type                = var.gcp_mdw_machine_type
  gcp_agent_machine_type              = var.gcp_agent_machine_type
  gcp_client_instance_name            = join("-", ["client", var.agent_version])
  gcp_server_instance_name            = join("-", ["server", var.agent_version])
  gcp_agent_serial_port_enable        = "true"
  gcp_agent_can_ip_forward            = "false"
  gcp_ssh_key                         = var.gcp_ssh_key
  startup_script                      = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.gcp_mdw_instance.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
}

resource "google_compute_network" "gcp_mgmt_vpc_network" {
  name                    = "${local.gcp_deployment}-${local.gcp_mgmt_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_resource_policy" "gcp_placement_group" {
  name   = "${local.gcp_deployment}-agent-deployment-policy"
  region = local.gcp_region_name
  group_placement_policy {
    vm_count    = var.gcp_agent_number * 2
    collocation = "COLLOCATED"
  }
}

resource "google_compute_subnetwork" "gcp_mgmt_subnet" {
  name                     = "${local.gcp_deployment}-${local.gcp_mgmt_subnet_name}"
  ip_cidr_range            = local.gcp_mgmt_subnet_ip_range
  network                  = google_compute_network.gcp_mgmt_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}

resource "google_compute_firewall" "gcp_mgmt_firewall_rule" {
  name = "${local.gcp_deployment}-${local.gcp_mgmt_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_mgmt_firewall_rule_direction
  network       = google_compute_network.gcp_mgmt_vpc_network.self_link
  priority      = local.gcp_mgmt_firewall_rule_priority
  source_ranges = local.gcp_allowed_cidr
}

resource "google_compute_firewall" "gcp_mdw_https_server_rule" {
  name     = "${local.gcp_deployment}-mdw-https-server"
  network  = google_compute_network.gcp_mgmt_vpc_network.self_link
  priority = 999
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = local.gcp_allowed_cidr
  target_tags   = ["https-server"]
}

/*
resource "google_compute_network" "gcp_test_vpc_network" {
  name                    = "${local.gcp_deployment}-${local.gcp_test_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
*/

/*
resource "google_compute_subnetwork" "gcp_test_subnet" {
  name                     = "${local.gcp_deployment}-${local.gcp_test_subnet_name}"
  ip_cidr_range            = local.gcp_test_subnet_ip_range
  network                  = google_compute_network.gcp_test_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}
*/
/*
resource "google_compute_firewall" "gcp_test_firewall_rule" {
  name = "${local.gcp_deployment}-${local.gcp_test_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_test_firewall_rule_direction
  network       = google_compute_network.gcp_test_vpc_network.self_link
  priority      = local.gcp_test_firewall_rule_priority
  source_ranges = local.gcp_test_firewall_rule_source_ip_ranges
}
*/
resource "google_compute_address" "gcp_mdw_ip" {
  name = "${local.gcp_deployment}-mdw-ip"
}

resource "google_compute_instance" "gcp_mdw_instance" {
  name                      = "${local.gcp_deployment}-${local.gcp_mdw_instance_name}"
  can_ip_forward            = local.gcp_mdw_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_mdw_machine_type
  allow_stopping_for_update = true
  tags                      = ["gcp-cyperf-controller"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/kt-nas-cyperf-dev/global/images/${var.mdw_version}"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
      nat_ip       = google_compute_address.gcp_mdw_ip.address
    }
  }
  metadata = {
    Owner              = local.gcp_owner
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_mdw_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }

  labels = {
    owner   = local.gcp_owner
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
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
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
  }
  /*
  network_interface {
    network    = google_compute_network.gcp_test_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_test_subnet.self_link
  }
  */
  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }
  //metadata_startup_script = local.startup_script
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo rm -rf /etc/portmanager/node_id.txt
    cyperfagent feature allow_mgmt_iface_for_test enable
    sudo cyperfagent controller set ${google_compute_instance.gcp_mdw_instance.network_interface.0.network_ip} --skip-restart
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

output "mdw_detail" {
  value = {
    "name" : google_compute_instance.gcp_mdw_instance.name,
    "private_ip" : google_compute_instance.gcp_mdw_instance.network_interface.0.network_ip,
    "public_ip" : google_compute_instance.gcp_mdw_instance.network_interface.0.access_config.0.nat_ip
  }
}
