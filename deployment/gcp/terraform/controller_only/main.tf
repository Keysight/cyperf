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
  gcp_owner_tag                    = var.gcp_owner_tag
  gcp_project_tag                  = var.gcp_project_tag
  gcp_options_tag                  = "MANUAL"
  gcp_mgmt_vpc_network_name        = "management-vpc-network"
  gcp_mgmt_subnet_name             = "management-subnet"
  gcp_mgmt_subnet_ip_range         = "172.16.5.0/24"
  gcp_mgmt_firewall_rule_name      = "management-firewall-rule"
  gcp_mgmt_firewall_rule_direction = "INGRESS"
  gcp_mgmt_firewall_rule_priority  = "1000"
  gcp_mgmt_firewall_rule_PORTS = [
    "22",
    "80",
    "443"
  ]
  gcp_allowed_cidr                 = concat(var.gcp_allowed_cidr, [local.gcp_mgmt_subnet_ip_range])
  gcp_mdw_instance_name                        = join("", ["cyperf-mdw-", var.mdw_version])
  gcp_mdw_serial_port_enable                   = "true"
  gcp_mdw_can_ip_forward                       = "false"
  gcp_mdw_custom_image_project_name            = var.gcp_project_name
  gcp_mdw_machine_type                         = var.gcp_mdw_machine_type
  gcp_ssh_key								   = var.gcp_ssh_key
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

resource "google_compute_firewall" "gcp_mgmt_firewall_rule" {
  name = "${local.gcp_owner_tag}-${local.gcp_mgmt_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_mgmt_firewall_rule_direction
  network       = google_compute_network.gcp_mgmt_vpc_network.self_link
  priority      = local.gcp_mgmt_firewall_rule_priority
  source_ranges = local.gcp_allowed_cidr
}

resource "google_compute_firewall" "gcp_mdw_https_server_rule" {
  name     = "${local.gcp_owner_tag}-mdw-https-server"
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

resource "google_compute_address" "gcp_mdw_ip" {
  name = "${local.gcp_owner_tag}-mdw-ip"
}

resource "google_compute_instance" "gcp_mdw_instance" {
  name                      = "${local.gcp_owner_tag}-${local.gcp_mdw_instance_name}"
  can_ip_forward            = local.gcp_mdw_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_mdw_machine_type
  allow_stopping_for_update = true
  tags                      = ["https-server"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/${local.gcp_mdw_custom_image_project_name}/global/images/${var.mdw_version}"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
    network_ip = "172.16.5.100"
    
    access_config {
      network_tier = "PREMIUM"
      nat_ip = google_compute_address.gcp_mdw_ip.address
    }
  }
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_mdw_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }

  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

output "mdw_detail" {
  value = {
    "name": google_compute_instance.gcp_mdw_instance.name,
    "private_ip" : google_compute_instance.gcp_mdw_instance.network_interface.0.network_ip,
    "public_ip" : google_compute_instance.gcp_mdw_instance.network_interface.0.access_config.0.nat_ip
  }
}
