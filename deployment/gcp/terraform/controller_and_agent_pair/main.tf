provider "google" {
  credentials = file("/var/lib/jenkins/appsec/resources/credentials/gcp/kt-nas-cyperf-dev-5b29ff75f49a.json")
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
  GCP_MGMT_FIREWALL_RULE_PORTS = [
    "22",
    "80",
    "443"
  ]
  GCP_MGMT_FIREWALL_RULE_SOURCE_IP_RANGES = "0.0.0.0/0"
  GCP_TEST_VPC_NETWORK_NAME           = "test-vpc-network"
  GCP_TEST_SUBNET_NAME                = "test-subnet"
  GCP_TEST_SUBNET_IP_RANGE            = "10.0.0.0/8"
  GCP_TEST_FIREWALL_RULE_NAME         = "test-firewall-rule"
  GCP_TEST_FIREWALL_RULE_DIRECTION    = "INGRESS"
  GCP_TEST_FIREWALL_RULE_PRIORITY     = "100"
  GCP_TEST_FIREWALL_RULE_PORTS        = "all"
  GCP_TEST_FIREWALL_RULE_SOURCE_IP_RANGES = [
    "0.0.0.0/0"
  ]
  GCP_TEST_VPC_NETWORK_PEER_NAME               = "test-vpc-network-peer"
  GCP_MDW_INSTANCE_NAME                        = join("", ["cyperf-mdw-v", var.mdw_version])
  GCP_MDW_SERIAL_PORT_ENABLE                   = "true"
  GCP_MDW_CAN_IP_FORWARD                       = "false"
  GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME            = var.GCP_PROJECT_NAME
  GCP_MDW_MACHINE_TYPE                         = var.GCP_MDW_MACHINE_TYPE
  GCP_MDW_IFACE_ETH0_PUBLIC_IP_ADDRESS_NAME    = "MDW-IP"
  GCP_agent_MACHINE_TYPE                       = var.GCP_AGENT_MACHINE_TYPE
  GCP_CLIENT_INSTANCE_NAME                     = join("-", ["client-agent", var.agent_version])
  GCP_SERVER_INSTANCE_NAME                     = join("-", ["server-agent", var.agent_version])
  GCP_agent_SERIAL_PORT_ENABLE                 = "true"
  GCP_agent_CAN_IP_FORWARD                     = "false"
  GCP_agent_CUSTOM_IMAGE_PROJECT_NAME          = var.GCP_PROJECT_NAME
  startup_script = "/bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.GCP_MDW_INSTANCE.network_interface.0.network_ip} >> /home/cyperf/gcp_image_init_log "
}

resource "google_compute_resource_policy" "GCP_AGENT_PLACEMENT_GROUP" {
  name   = "${local.GCP_OWNER_TAG}-agent-deployment-policy"
  region = local.GCP_REGION_NAME
  group_placement_policy {
    vm_count = 2
    collocation = "COLLOCATED"
  }
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

resource "google_compute_firewall" "GCP_MGMT_FIREWALL_RULE" {
  name = "${local.GCP_OWNER_TAG}-${local.GCP_MGMT_FIREWALL_RULE_NAME}"
  allow {
    protocol = "all"
  }
  direction     = local.GCP_MGMT_FIREWALL_RULE_DIRECTION
  network       = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
  priority      = local.GCP_MGMT_FIREWALL_RULE_PRIORITY
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "MDW_HTTPS_SERVER" {
  name     = "${local.GCP_OWNER_TAG}-mdw-https-server"
  network  = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
  priority = 999
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_network" "GCP_TEST_VPC_NETWORK" {
  name                    = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_VPC_NETWORK_NAME}"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "GCP_TEST_SUBNET" {
  name                     = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_SUBNET_NAME}"
  ip_cidr_range            = local.GCP_TEST_SUBNET_IP_RANGE
  network                  = google_compute_network.GCP_TEST_VPC_NETWORK.self_link
  region                   = local.GCP_REGION_NAME
  private_ip_google_access = true
}

resource "google_compute_firewall" "GCP_TEST_FIREWALL_RULE" {
  name = "${local.GCP_OWNER_TAG}-${local.GCP_TEST_FIREWALL_RULE_NAME}"
  allow {
    protocol = "all"
  }
  direction     = local.GCP_TEST_FIREWALL_RULE_DIRECTION
  network       = google_compute_network.GCP_TEST_VPC_NETWORK.self_link
  priority      = local.GCP_TEST_FIREWALL_RULE_PRIORITY
  source_ranges = local.GCP_TEST_FIREWALL_RULE_SOURCE_IP_RANGES
}

resource "google_compute_address" "GCP_MDW_IP" {
  name = "${local.GCP_OWNER_TAG}-mdw-ip"
}

resource "google_compute_instance" "GCP_MDW_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_MDW_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_MDW_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = "zones/${local.GCP_ZONE_NAME}/machineTypes/${local.GCP_MDW_MACHINE_TYPE}"
  allow_stopping_for_update = true
  tags                      = ["https-server"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME}/global/images/cyperf-mdw-v${var.mdw_version}"
    }
  }
  network_interface {
    network    = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
    subnetwork = google_compute_subnetwork.GCP_MGMT_SUBNET.self_link
    network_ip = "172.16.5.100"
    
    access_config {
      network_tier = "PREMIUM"
      nat_ip = google_compute_address.GCP_MDW_IP.address
    }
  }
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = local.GCP_MDW_SERIAL_PORT_ENABLE
    ssh-keys           = "cyperf:${file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")}"
  }

  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

resource "google_compute_instance" "GCP_CLIENT_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_CLIENT_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_agent_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = "zones/${local.GCP_ZONE_NAME}/machineTypes/${local.GCP_agent_MACHINE_TYPE}"
  allow_stopping_for_update = true
  
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_agent_CUSTOM_IMAGE_PROJECT_NAME}/global/images/cyperf-agent-${var.agent_version}"
    }
  }
  tags = [ "gcp-client" ]
  network_interface {
    network    = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
    subnetwork = google_compute_subnetwork.GCP_MGMT_SUBNET.self_link
    network_ip = "172.16.5.101"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = google_compute_network.GCP_TEST_VPC_NETWORK.self_link
    subnetwork = google_compute_subnetwork.GCP_TEST_SUBNET.self_link
    network_ip = "10.0.0.2"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  scheduling{
    on_host_maintenance  = "TERMINATE"
    automatic_restart = false
  }
  resource_policies         = [google_compute_resource_policy.GCP_AGENT_PLACEMENT_GROUP.self_link]
  metadata_startup_script = local.startup_script
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = local.GCP_agent_SERIAL_PORT_ENABLE
    ssh-keys           = "cyperf:${file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")}"
  }
  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

resource "google_compute_instance" "GCP_SERVER_INSTANCE" {
  name                      = "${local.GCP_OWNER_TAG}-${local.GCP_SERVER_INSTANCE_NAME}"
  can_ip_forward            = local.GCP_agent_CAN_IP_FORWARD
  zone                      = local.GCP_ZONE_NAME
  machine_type              = "zones/${local.GCP_ZONE_NAME}/machineTypes/${local.GCP_agent_MACHINE_TYPE}"
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.GCP_agent_CUSTOM_IMAGE_PROJECT_NAME}/global/images/cyperf-agent-${var.agent_version}"
    }
  }
  tags = [ "gcp-server" ]
  network_interface {
    network    = google_compute_network.GCP_MGMT_VPC_NETWORK.self_link
    subnetwork = google_compute_subnetwork.GCP_MGMT_SUBNET.self_link
    network_ip = "172.16.5.102"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = google_compute_network.GCP_TEST_VPC_NETWORK.self_link
    subnetwork = google_compute_subnetwork.GCP_TEST_SUBNET.self_link
    network_ip = "10.0.0.3"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  scheduling{
    on_host_maintenance  = "TERMINATE"
    automatic_restart = false
  }
  resource_policies         = [google_compute_resource_policy.GCP_AGENT_PLACEMENT_GROUP.self_link]
  metadata_startup_script = local.startup_script
  metadata = {
    Owner              = local.GCP_OWNER_TAG
    Project            = local.GCP_PROJECT_TAG
    Options            = local.GCP_OPTIONS_TAG
    serial-port-enable = local.GCP_agent_SERIAL_PORT_ENABLE
    ssh-keys           = "cyperf:${file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")}"
  }
  labels = {
    owner   = replace(replace(local.GCP_OWNER_TAG, ".", "-"), "@", "-")
    project = lower(local.GCP_PROJECT_TAG)
    options = lower(local.GCP_OPTIONS_TAG)
  }
}

output "mdw_detail" {
  value = {
    "name": google_compute_instance.GCP_MDW_INSTANCE.name,
    "private_ip" : google_compute_instance.GCP_MDW_INSTANCE.network_interface.0.network_ip,
    "public_ip" : google_compute_instance.GCP_MDW_INSTANCE.network_interface.0.access_config.0.nat_ip
  }
}

output "agents_detail"{
  value = [
    {
      "name": google_compute_instance.GCP_CLIENT_INSTANCE.name,
      "management_private_ip": google_compute_instance.GCP_CLIENT_INSTANCE.network_interface.0.network_ip,
      "management_public_ip": google_compute_instance.GCP_CLIENT_INSTANCE.network_interface.0.access_config.0.nat_ip
    },
    {
      "name": google_compute_instance.GCP_SERVER_INSTANCE.name,
      "management_private_ip": google_compute_instance.GCP_SERVER_INSTANCE.network_interface.0.network_ip,
      "management_public_ip": google_compute_instance.GCP_SERVER_INSTANCE.network_interface.0.access_config.0.nat_ip
    }
  ]
}

