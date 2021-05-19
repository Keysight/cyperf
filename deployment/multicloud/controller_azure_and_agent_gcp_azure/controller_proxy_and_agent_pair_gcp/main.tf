provider "google" {
  credentials = file(var.GCP_CREDENTIALS)
  project     = var.gcp_project_name
  region      = var.gcp_region_name
  zone        = var.gcp_zone_name
}

locals {
  gcp_project_name                 = var.gcp_project_name
  gcp_region_name                  = var.gcp_region_name
  gcp_zone_name                    = var.gcp_zone_name
  gcp_owner_tag                    = var.gcp_owner_tag
  gcp_project_tag                  = var.gcp_project_tag
  gcp_options_tag                  = "MANUAL"
  gcp_mgmt_firewall_rule_name      = "management-firewall-rule"
  gcp_mgmt_firewall_rule_name_ERG  = "management-firewall-rule-erg"
  gcp_mgmt_firewall_rule_direction = "INGRESS"
  gcp_mgmt_firewall_rule_priority  = "1000"
  gcp_mdw_custom_image_project_name = var.gcp_project_name
  gcp_mgmt_firewall_rule_PORTS = [
    "22",
    "80",
    "443"
  ]
  gcp_mgmt_firewall_rule_SOURCE_IP_RANGES = "0.0.0.0/0"
  GCP_CONSOLE_FIREWALL_RULE_NAME          = "gcp-console-firewall-rule"
  GCP_CONSOLE_FIREWALL_RULE_DIRECTION     = "INGRESS"
  GCP_CONSOLE_FIREWALL_RULE_PRIORITY      = "100"
  GCP_CONSOLE_FIREWALL_RULE_PORTS = [
    "22"
  ]
  GCP_CONSOLE_FIREWALL_RULE_SOURCE_IP_RANGES = [
    "10.0.0.0/8",
    "193.226.172.42",
    "193.226.172.40/29",
    "35.190.247.0/24",
    "35.191.0.0/16",
    "64.233.160.0/19",
    "66.102.0.0/20",
    "66.249.80.0/20",
    "72.14.192.0/18",
    "74.125.0.0/16",
    "108.177.8.0/21",
    "108.177.96.0/19",
    "130.211.0.0/22",
    "172.217.0.0/19",
    "172.217.32.0/20",
    "172.217.128.0/19",
    "172.217.160.0/20",
    "172.217.192.0/19",
    "172.253.56.0/21",
    "172.253.112.0/20",
    "173.194.0.0/16",
    "209.85.128.0/17",
    "216.58.192.0/19",
    "216.239.32.0/19"
  ]
  GCP_CONTROL_FIREWALL_RULE_NAME      = "control-firewall-rule"
  GCP_CONTROL_FIREWALL_RULE_DIRECTION = "INGRESS"
  GCP_CONTROL_FIREWALL_RULE_PRIORITY  = "1003"
  GCP_CONTROL_FIREWALL_RULE_PORTS     = "all"
  gcp_test_firewall_rule_name         = "test-firewall-rule"
  gcp_test_firewall_rule_direction    = "INGRESS"
  gcp_test_firewall_rule_priority     = "1000"
  gcp_test_firewall_rule_PORTS        = "all"
  gcp_test_firewall_rule_source_ip_ranges = [
    "0.0.0.0/0"
  ]
  gcp_test_vpc_network_PEER_NAME               = "test-vpc-network-peer"
  gcp_nats_instance_name                     = join("-", ["cyperf-broker", var.broker_image])
  gcp_broker_serial_port_enable                = "true"
  gcp_broker_can_ip_forward                    = "false"
  gcp_broker_custom_image_project_name         = var.gcp_project_name
  gcp_broker_machine_type                      = var.gcp_broker_machine_type
  gcp_agent_machine_type                       = var.gcp_agent_machine_type
  GCP_AGENT1_INSTANCE_NAME                     = join("-", ["agent", var.agent_version, "01"])
  GCP_AGENT2_INSTANCE_NAME                     = join("-", ["agent", var.agent_version, "02"])
  gcp_agent_serial_port_enable                 = "true"
  gcp_agent_can_ip_forward                     = "false"
  gcp_agent_custom_image_project_name          = var.gcp_project_name
}

data "google_compute_network" "management_vpc" {
  name                     = var.gcp_mgmt_vpc_network_name
  project                  = var.gcp_project_name
}

data "google_compute_subnetwork" "management_subnet" {
  name                     = var.gcp_mgmt_subnet_name
  project                  = var.gcp_project_name
}

data "google_compute_network" "test_vpc" {
  name                    = var.gcp_test_vpc_network_name
  project                  = var.gcp_project_name
}

data "google_compute_subnetwork" "test_subnet" {
  name                     = var.gcp_test_subnet_name
  project                  = var.gcp_project_name
}

resource "google_compute_firewall" "gcp_mgmt_firewall_rule" {
  name = "${local.gcp_owner_tag}-${local.gcp_mgmt_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_mgmt_firewall_rule_direction
  network       = data.google_compute_network.management_vpc.name
  priority      = local.gcp_mgmt_firewall_rule_priority
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcp_nats_https_server" {
  name     = "${local.gcp_owner_tag}-nats-https-server"
  network  = data.google_compute_network.management_vpc.name
  priority = 999
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gcp-https-server"]
}

resource "google_compute_firewall" "gcp_test_firewall_rule" {
  name = "${local.gcp_owner_tag}-${local.gcp_test_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_test_firewall_rule_direction
  network       = data.google_compute_network.test_vpc.self_link
  priority      = local.gcp_test_firewall_rule_priority
  source_ranges = local.gcp_test_firewall_rule_source_ip_ranges
}

resource "google_compute_route" "GCP_TEST_COMPUTE_ROUTE" {
  name        = "${local.gcp_owner_tag}-internet-route"
  dest_range  = "0.0.0.0/0"
  network     = data.google_compute_network.test_vpc.name
  next_hop_gateway = "global/gateways/default-internet-gateway"
  priority    = 100
}

resource "google_compute_instance" "gcp_nats_instance" {
  name                      = "${local.gcp_owner_tag}-${local.gcp_nats_instance_name}"
  can_ip_forward            = local.gcp_broker_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = "zones/${local.gcp_zone_name}/machineTypes/${local.gcp_broker_machine_type}"
  allow_stopping_for_update = true
  tags                      = ["gcp-https-server"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.gcp_mdw_custom_image_project_name}/global/images/${var.broker_image}"
    }
  }
  network_interface {
    network    = data.google_compute_network.management_vpc.self_link
    subnetwork = data.google_compute_subnetwork.management_subnet.self_link
    access_config {
    }
  }
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = "true"
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }

  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

resource "google_compute_instance" "GCP_AGENT1_INSTANCE" {
  name                      = "${local.gcp_owner_tag}-${local.GCP_AGENT1_INSTANCE_NAME}"
  can_ip_forward            = local.gcp_agent_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_agent_machine_type
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.gcp_agent_custom_image_project_name}/global/images/${var.agent_version}"
    }
  }
  network_interface {
    network    = data.google_compute_network.management_vpc.self_link
    subnetwork = data.google_compute_subnetwork.management_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = data.google_compute_network.test_vpc.self_link
    subnetwork = data.google_compute_subnetwork.test_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  metadata_startup_script = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.gcp_nats_instance.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }
  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

resource "google_compute_instance" "GCP_AGENT2_INSTANCE" {
  name                      = "${local.gcp_owner_tag}-${local.GCP_AGENT2_INSTANCE_NAME}"
  can_ip_forward            = local.gcp_agent_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_agent_machine_type
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.gcp_agent_custom_image_project_name}/global/images/${var.agent_version}"
    }
  }
  network_interface {
    network    = data.google_compute_network.management_vpc.self_link
    subnetwork = data.google_compute_subnetwork.management_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = data.google_compute_network.test_vpc.self_link
    subnetwork = data.google_compute_subnetwork.test_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  metadata_startup_script = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.gcp_nats_instance.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }
  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

output "broker_public_ip" {
  value = google_compute_instance.gcp_nats_instance.network_interface.0.access_config.0.nat_ip
}

output "agents_detail"{
  value = [
    {
      "name": google_compute_instance.GCP_AGENT1_INSTANCE.name,
      "management_private_ip": google_compute_instance.GCP_AGENT1_INSTANCE.network_interface.0.network_ip,
      "management_public_ip": google_compute_instance.GCP_AGENT1_INSTANCE.network_interface.0.access_config.0.nat_ip
    },
    {
      "name": google_compute_instance.GCP_AGENT2_INSTANCE.name,
      "management_private_ip": google_compute_instance.GCP_AGENT2_INSTANCE.network_interface.0.network_ip,
      "management_public_ip":  google_compute_instance.GCP_AGENT2_INSTANCE.network_interface.0.access_config.0.nat_ip
    }
  ]
}

