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
  GCP_MGMT_VPC_NETWORK_NAME        = "management-vpc-network"
  GCP_MGMT_SUBNET_NAME             = "management-subnet"
  GCP_MGMT_SUBNET_IP_RANGE         = "172.16.5.0/24"
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
  GCP_TEST_VPC_NETWORK_NAME           = "test-vpc-network"
  GCP_TEST_SUBNET_NAME                = "test-subnet"
  GCP_TEST_SUBNET_IP_RANGE            = "10.0.0.0/8"
  GCP_TEST_FIREWALL_RULE_NAME         = "test-firewall-rule"
  GCP_TEST_FIREWALL_RULE_DIRECTION    = "INGRESS"
  GCP_TEST_FIREWALL_RULE_PRIORITY     = "1000"
  GCP_TEST_FIREWALL_RULE_PORTS        = "all"
  GCP_TEST_FIREWALL_RULE_SOURCE_IP_RANGES = [
    "0.0.0.0/0"
  ]
  GCP_TEST_VPC_NETWORK_PEER_NAME               = "test-vpc-network-peer"
  GCP_BROKER_SERIAL_PORT_ENABLE                = "true"
  GCP_BROKER_CAN_IP_FORWARD                    = "false"
  GCP_BROKER_CUSTOM_IMAGE_PROJECT_NAME         = var.GCP_PROJECT_NAME
  GCP_agent_SERIAL_PORT_ENABLE                 = "true"
  GCP_agent_CAN_IP_FORWARD                     = "false"
  GCP_agent_CUSTOM_IMAGE_PROJECT_NAME          = var.GCP_PROJECT_NAME
}

resource "google_compute_network" "GCP_MGMT_VPC_NETWORK" {
  name                    = "${local.GCP_OWNER_TAG}-${local.GCP_MGMT_VPC_NETWORK_NAME}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "GCP_MGMT_SUBNET" {
  name                     = "${local.GCP_OWNER_TAG}-${local.GCP_MGMT_SUBNET_NAME}"
  ip_cidr_range            = local.GCP_MGMT_SUBNET_IP_RANGE
  network                  = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
  region                   = local.GCP_REGION_NAME
  private_ip_google_access = true
}

resource "google_compute_network" "GCP_TEST_VPC_NETWORK" {
  name                    = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_VPC_NETWORK_NAME}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "GCP_TEST_SUBNET" {
  name                     = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_SUBNET_NAME}"
  ip_cidr_range            = local.GCP_TEST_SUBNET_IP_RANGE
  network                  = google_compute_network.GCP_TEST_VPC_NETWORK.self_link
  region                   = local.GCP_REGION_NAME
  private_ip_google_access = true
}




