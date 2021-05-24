provider "google" {
  credentials = file(var.GCP_CREDENTIALS)
  project     = var.GCP_PROJECT_NAME
  region      = var.GCP_REGION_NAME
  zone        = var.GCP_ZONE_NAME
}

locals {
  GCP_PROJECT_NAME                 = var.GCP_PROJECT_NAME
  GCP_REGION_NAME                  = var.GCP_REGION_NAME
  GCP_ZONE_NAME                    = var.GCP_ZONE_NAME
  GCP_OWNER_TAG                    = var.GCP_OWNER_TAG
  GCP_PROJECT_TAG                  = var.GCP_PROJECT_TAG
  GCP_OPTIONS_TAG                  = "MANUAL"
  GCP_MGMT_FIREWALL_RULE_NAME      = "management-firewall-rule"
  GCP_MGMT_FIREWALL_RULE_NAME_ERG  = "management-firewall-rule-erg"
  GCP_MGMT_FIREWALL_RULE_DIRECTION = "INGRESS"
  GCP_MGMT_FIREWALL_RULE_PRIORITY  = "1000"
  GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME = var.GCP_PROJECT_NAME
  GCP_MGMT_FIREWALL_RULE_PORTS = [
    "22",
    "80",
    "443"
  ]
  GCP_MGMT_FIREWALL_RULE_SOURCE_IP_RANGES = "0.0.0.0/0"
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
  GCP_TEST_FIREWALL_RULE_NAME         = "test-firewall-rule"
  GCP_TEST_FIREWALL_RULE_DIRECTION    = "INGRESS"
  GCP_TEST_FIREWALL_RULE_PRIORITY     = "1000"
  GCP_TEST_FIREWALL_RULE_PORTS        = "all"
  GCP_TEST_FIREWALL_RULE_SOURCE_IP_RANGES = [
    "0.0.0.0/0"
  ]
  GCP_TEST_VPC_NETWORK_PEER_NAME               = "test-vpc-network-peer"
  GCP_BROKER_INSTANCE_NAME                     = join("-", ["cyperf-broker", var.broker_image])
  GCP_BROKER_SERIAL_PORT_ENABLE                = "true"
  GCP_BROKER_CAN_IP_FORWARD                    = "false"
  GCP_BROKER_CUSTOM_IMAGE_PROJECT_NAME         = var.GCP_PROJECT_NAME
  GCP_BROKER_MACHINE_TYPE                      = var.GCP_BROKER_MACHINE_TYPE
  GCP_agent_MACHINE_TYPE                       = var.GCP_AGENT_MACHINE_TYPE
  GCP_AGENT1_INSTANCE_NAME                     = join("-", ["agent", var.agent_version, "01"])
  GCP_AGENT2_INSTANCE_NAME                     = join("-", ["agent", var.agent_version, "02"])
  GCP_agent_SERIAL_PORT_ENABLE                 = "true"
  GCP_agent_CAN_IP_FORWARD                     = "false"
  GCP_agent_CUSTOM_IMAGE_PROJECT_NAME          = var.GCP_PROJECT_NAME
}

data "google_compute_network" "management_vpc" {
  name                     = var.GCP_MGMT_VPC_NETWORK_NAME
  project                  = var.GCP_PROJECT_NAME
}

data "google_compute_subnetwork" "management_subnet" {
  name                     = var.GCP_MGMT_SUBNET_NAME
  project                  = var.GCP_PROJECT_NAME
}

data "google_compute_network" "test_vpc" {
  name                    = var.GCP_TEST_VPC_NETWORK_NAME
  project                  = var.GCP_PROJECT_NAME
}

data "google_compute_subnetwork" "test_subnet" {
  name                     = var.GCP_TEST_SUBNET_NAME
  project                  = var.GCP_PROJECT_NAME
}

resource "google_compute_firewall" "GCP_MGMT_FIREWALL_RULE" {
  name = "${local.GCP_OWNER_TAG}-${local.GCP_MGMT_FIREWALL_RULE_NAME}"
  allow {
    protocol = "all"
  }
  direction     = local.GCP_MGMT_FIREWALL_RULE_DIRECTION
  network       = data.google_compute_network.management_vpc.name
  priority      = local.GCP_MGMT_FIREWALL_RULE_PRIORITY
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "GCP_NATS_HTTPS_SERVER" {
  name     = "${local.GCP_OWNER_TAG}-nats-https-server"
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

resource "google_compute_firewall" "GCP_TEST_FIREWALL_RULE" {
  name = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_FIREWALL_RULE_NAME}"
  allow {
    protocol = "all"
  }
  direction     = local.GCP_TEST_FIREWALL_RULE_DIRECTION
  network       = data.google_compute_network.test_vpc.self_link
  priority      = local.GCP_TEST_FIREWALL_RULE_PRIORITY
  source_ranges = local.GCP_TEST_FIREWALL_RULE_SOURCE_IP_RANGES
}

resource "google_compute_route" "GCP_TEST_COMPUTE_ROUTE" {
  name        = "${local.GCP_OWNER_TAG}-internet-route"
  dest_range  = "0.0.0.0/0"
  network     = data.google_compute_network.test_vpc.name
  next_hop_gateway = "global/gateways/default-internet-gateway"
  priority    = 100
}

resource "google_compute_instance" "GCP_BROKER_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_BROKER_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_BROKER_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = "zones/${local.GCP_ZONE_NAME}/machineTypes/${local.GCP_BROKER_MACHINE_TYPE}"
  allow_stopping_for_update = true
  tags                      = ["gcp-https-server"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME}/global/images/${var.broker_image}"
    }
  }
  network_interface {
    network    = data.google_compute_network.management_vpc.self_link
    subnetwork = data.google_compute_subnetwork.management_subnet.self_link
    access_config {
    }
  }
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = "true"
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }

  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

resource "google_compute_instance" "GCP_AGENT1_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_AGENT1_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_agent_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = local.GCP_agent_MACHINE_TYPE
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_agent_CUSTOM_IMAGE_PROJECT_NAME}/global/images/${var.agent_version}"
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
  metadata_startup_script = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.GCP_BROKER_INSTANCE.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = local.GCP_agent_SERIAL_PORT_ENABLE
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }
  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

resource "google_compute_instance" "GCP_AGENT2_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_AGENT2_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_agent_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = local.GCP_agent_MACHINE_TYPE
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_agent_CUSTOM_IMAGE_PROJECT_NAME}/global/images/${var.agent_version}"
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
  metadata_startup_script = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.GCP_BROKER_INSTANCE.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = local.GCP_agent_SERIAL_PORT_ENABLE
    ssh-keys           = "${var.SSH_USER}:${file(var.SSH_KEY_PATH)}"
  }
  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

output "broker_public_ip" {
  value = google_compute_instance.GCP_BROKER_INSTANCE.network_interface.0.access_config.0.nat_ip
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

