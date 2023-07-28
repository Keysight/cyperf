provider "google" {
  credentials = file(var.gcp_credential_file)
  project     = var.gcp_project_name
  region      = var.gcp_region_name
  zone        = var.gcp_zone_name
}

provider "google-beta" {
  credentials = file("kt-nas-cyperf-dev-5b29ff75f49a.json")
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
  gcp_allowed_cidr                 = concat(var.gcp_allowed_cidr, [local.gcp_mgmt_subnet_ip_range])
  gcp_test_vpc_network_name           = "test-vpc-network"
  gcp_test_subnet_name                = "test-subnet"
  gcp_test_subnet_ip_range            = "10.0.0.0/8"
  gcp_test_firewall_rule_name         = "test-firewall-rule"
  gcp_test_firewall_rule_direction    = "INGRESS"
  gcp_test_firewall_rule_priority     = "1000"
  gcp_test_firewall_rule_source_ip_ranges = [
    "0.0.0.0/0"
  ]
  gcp_nats_instance_name                       =  var.broker_image
  gcp_broker_serial_port_enable                = "true"
  gcp_broker_can_ip_forward                    = "false"
  gcp_broker_custom_image_project_name         = var.gcp_project_name
  gcp_broker_machine_type                      = var.gcp_broker_machine_type
  gcp_agent_machine_type                       = var.gcp_agent_machine_type
  gcp_client_agent_instance_name               = join("-", ["client-agent", var.agent_version])
  gcp_server_agent_instance_name               = join("-", ["server-agent", var.agent_version])
  gcp_agent_serial_port_enable                 = "true"
  gcp_agent_can_ip_forward                     = "false"
  gcp_agent_custom_image_project_name          = var.gcp_project_name
  gcp_ssh_key								   = var.gcp_ssh_key
  startup_script = <<SCRIPT
                            /bin/bash /usr/bin/image_init_gcp.sh ${google_compute_instance.gcp_nats_instance.network_interface.0.network_ip} >> image_init_behind_alb_log
                            sudo cyperfagent configuration reload"
                    SCRIPT
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

resource "google_compute_firewall" "gcp_nats_https_server" {
  name     = "${local.gcp_owner_tag}-nats-https-server"
  network  = google_compute_network.gcp_mgmt_vpc_network.self_link
  priority = 999
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
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


resource "google_compute_firewall" "gcp_test_firewall_rule" {
  name = "${local.gcp_owner_tag}-${local.gcp_test_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_test_firewall_rule_direction
  network       = google_compute_network.gcp_test_vpc_network.self_link
  priority      = local.gcp_test_firewall_rule_priority
  source_ranges = local.gcp_test_firewall_rule_source_ip_ranges
}

resource "google_compute_address" "gcp_nats_ip" {
  name = "${local.gcp_owner_tag}-broker-ip"
}

resource "google_compute_instance" "gcp_nats_instance" {
  name                      = "${local.gcp_owner_tag}-${local.gcp_nats_instance_name}"
  can_ip_forward            = local.gcp_broker_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_broker_machine_type
  allow_stopping_for_update = true
  tags                      = ["https-server"]
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/kt-nas-cyperf-dev/global/images/${var.broker_image}"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
    network_ip = "172.16.5.100"
    access_config {
      nat_ip = google_compute_address.gcp_nats_ip.address
    }
  }
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = "true"
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }

  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

resource "google_compute_instance" "gcp_client_agent_instance" {
  name                      = "${local.gcp_owner_tag}-${local.gcp_client_agent_instance_name}"
  can_ip_forward            = local.gcp_agent_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_agent_machine_type
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/kt-nas-cyperf-dev/global/images/${var.agent_version}"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_test_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_test_subnet.self_link
    network_ip = "10.0.0.3"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  metadata_startup_script = local.startup_script
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }
  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
  tags = [ "gcp-agent" ]
}


resource "google_compute_instance" "gcp_server_agent_instance" {
  name                      = "${local.gcp_owner_tag}-${local.gcp_server_agent_instance_name}"
  can_ip_forward            = local.gcp_agent_can_ip_forward
  zone                      = local.gcp_zone_name
  machine_type              = local.gcp_agent_machine_type
  allow_stopping_for_update = true
  boot_disk {
    device_name = "persistent-disk-0"
    auto_delete = "true"
    initialize_params {
      image = "projects/kt-nas-cyperf-dev/global/images/${var.agent_version}"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_mgmt_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_mgmt_subnet.self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
  network_interface {
    network    = google_compute_network.gcp_test_vpc_network.self_link
    subnetwork = google_compute_subnetwork.gcp_test_subnet.self_link
    network_ip = "10.0.0.2"
    access_config {
      network_tier = "PREMIUM"
    }
  }
  metadata_startup_script = local.startup_script
  metadata = {
    Owner              = local.gcp_owner_tag
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }
  labels = {
    owner   = replace(replace(local.gcp_owner_tag, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
  tags = [ "gcp-agent" ]
}

output "broker_public_ip" {
  value = google_compute_instance.gcp_nats_instance.network_interface.0.access_config.0.nat_ip
}

output "agents_detail"{
  value = [
    {
      "name": google_compute_instance.gcp_client_agent_instance.name,
      "management_private_ip": google_compute_instance.gcp_client_agent_instance.network_interface.0.network_ip,
      "management_public_ip": google_compute_instance.gcp_client_agent_instance.network_interface.0.access_config.0.nat_ip
    },
    {
      "name": google_compute_instance.gcp_server_agent_instance.name,
      "management_private_ip": google_compute_instance.gcp_server_agent_instance.network_interface.0.network_ip,
      "management_public_ip": google_compute_instance.gcp_server_agent_instance.network_interface.0.access_config.0.nat_ip
    }
  ]
}



