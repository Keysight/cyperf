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
  gcp_mgmt_vpc_network_name        = "management-vpc-network"
  gcp_mgmt_subnet_name             = "management-subnet"
  gcp_mgmt_subnet_ip_range         = "172.16.5.0/24"
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
  gcp_test_vpc_network_name           = "test-vpc-network"
  gcp_test_subnet_name                = "test-subnet"
  gcp_test_subnet_ip_range            = "10.0.0.0/8"
  gcp_test_firewall_rule_name         = "test-firewall-rule"
  gcp_test_firewall_rule_direction    = "INGRESS"
  gcp_test_firewall_rule_priority     = "1000"
  gcp_test_firewall_rule_PORTS        = "all"
  gcp_test_firewall_rule_source_ip_ranges = [
    "0.0.0.0/0"
  ]
  gcp_test_vpc_network_PEER_NAME               = "test-vpc-network-peer"
  gcp_broker_serial_port_enable                = "true"
  gcp_broker_can_ip_forward                    = "false"
  gcp_broker_custom_image_project_name         = var.gcp_project_name
  gcp_agent_serial_port_enable                 = "true"
  gcp_agent_can_ip_forward                     = "false"
  gcp_agent_custom_image_project_name          = var.gcp_project_name
}

resource "google_compute_network" "gcp_mgmt_vpc_network" {
  name                    = "${local.gcp_owner_tag}-${local.gcp_mgmt_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "gcp_mgmt_subnet" {
  name                     = "${local.gcp_owner_tag}-${local.gcp_mgmt_subnet_name}"
  ip_cidr_range            = local.gcp_mgmt_subnet_ip_range
  network                  = google_compute_network.gcp_mgmt_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}

resource "google_compute_network" "gcp_test_vpc_network" {
  name                    = "${local.gcp_owner_tag}-${local.gcp_test_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "gcp_test_subnet" {
  name                     = "${local.gcp_owner_tag}-${local.gcp_test_subnet_name}"
  ip_cidr_range            = local.gcp_test_subnet_ip_range
  network                  = google_compute_network.gcp_test_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}




