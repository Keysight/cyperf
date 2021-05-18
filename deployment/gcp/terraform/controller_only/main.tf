provider "google" {
  credentials = file(var.GCP_CREDENTIALS_FILE)
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
  GCP_MGMT_FIREWALL_RULE_DIRECTION = "INGRESS"
  GCP_MGMT_FIREWALL_RULE_PRIORITY  = "1000"
  GCP_MGMT_FIREWALL_RULE_PORTS = [
    "22",
    "80",
    "443"
  ]
  GCP_MGMT_FIREWALL_RULE_SOURCE_IP_RANGES = "0.0.0.0/0"  
  GCP_MDW_INSTANCE_NAME                        = join("", ["cyperf-mdw-", var.mdw_version])
  GCP_MDW_SERIAL_PORT_ENABLE                   = "true"
  GCP_MDW_CAN_IP_FORWARD                       = "false"
  GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME            = var.GCP_PROJECT_NAME
  GCP_MDW_MACHINE_TYPE                         = var.GCP_MDW_MACHINE_TYPE
  GCP_MDW_IFACE_ETH0_PUBLIC_IP_ADDRESS_NAME    = "MDW-IP"
  GCP_SSH_KEY								   = var.GCP_SSH_KEY
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
      image = "projects/${local.GCP_MDW_CUSTOM_IMAGE_PROJECT_NAME}/global/images/${var.mdw_version}"
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
    ssh-keys           = "cyperf:${file(local.GCP_SSH_KEY)}"
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
