provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

provider "google" {
  credentials = file(var.gcp_credential_file)
  project     = var.gcp_project_name
  region      = var.gcp_region_name
  zone        = var.gcp_zone_name
}

locals {
  mdw_name = "${var.deployment_name}-mdw-${var.mdw_version}"
  client_name = "${var.deployment_name}-client-${var.agent_version}"
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      sh /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address} >> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  gcp_project_name                 = var.gcp_project_name
  gcp_region_name                  = var.gcp_region_name
  gcp_zone_name                    = var.gcp_zone_name
  deployment_name                    = var.deployment_name
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
  gcp_test_vpc_network_name           = "test-vpc-network"
  gcp_test_subnet_name                = "test-subnet"
  gcp_test_subnet_ip_range            = "10.0.0.0/8"
  gcp_test_firewall_rule_name         = "test-firewall-rule"
  gcp_test_firewall_rule_direction    = "INGRESS"
  gcp_test_firewall_rule_priority     = "1000"
  gcp_test_firewall_rule_source_ip_ranges = [
    "0.0.0.0/0"
  ]
  gcp_nats_instance_name                     = join("-", ["cyperf-broker", var.broker_image])
  gcp_broker_serial_port_enable                = "true"
  gcp_broker_can_ip_forward                    = "false"
  gcp_broker_custom_image_project_name         = var.gcp_project_name
  gcp_broker_machine_type                      = var.gcp_broker_machine_type
  gcp_agent_machine_type                       = var.gcp_agent_machine_type
  gcp_server_agent_instance_name               = join("-", ["server-agent", var.agent_version])
  gcp_agent_serial_port_enable                 = "true"
  gcp_agent_can_ip_forward                     = "false"
  gcp_agent_custom_image_project_name          = var.gcp_project_name
  gcp_ssh_key								   = var.public_key
  startup_script = <<SCRIPT
                            /bin/bash
                            /usr/bin/image_init_gcp.sh ${google_compute_instance.gcp_nats_instance.network_interface.0.network_ip} >> image_init_behind_alb_log
                            sudo cyperfagent configuration reload"
                    SCRIPT
}

resource "azurerm_resource_group" "azr_automation" {
  name     = var.deployment_name
  location = var.azure_region_name
}

resource "azurerm_proximity_placement_group" "azr_proximity_placement" {
  name                = "${var.deployment_name}-proximity-placement"
  location            = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name

  tags = {
    environment = "test-enviroment"
  }
}

resource "azurerm_network_security_group" "azr_automation" {
  name                = "${var.deployment_name}-sg"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
    security_rule {
    name                       = var.deployment_name
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "azr_automation" {
  name                = "${var.deployment_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
}

resource "azurerm_subnet" "azr_automation_management_network" {
  name                 = "${var.deployment_name}-management-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "azr_automation_test_network" {
  name                 = "${var.deployment_name}-test-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "azr_automation_mdw_public_ip" {
  name                = "${var.deployment_name}-cyperf-mdw-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_1_public_ip" {
  name                = "${var.deployment_name}-cyperf-agent1-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_mdw_nic" {
  name                = "${var.deployment_name}-mdw-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.deployment_name}-mdw-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_mng_nic" {
  name                = "${var.deployment_name}-agent-1-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.deployment_name}-agent-1-management-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_test_nic" {
  name                = "${var.deployment_name}-agent-1-test-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "${var.deployment_name}-agent-1-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_test_network.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = local.mdw_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_mdw_machine_type
  admin_username      = "cyperf"
  network_interface_ids = [
    azurerm_network_interface.azr_automation_mdw_nic.id,
  ]

  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name = "keysight-cyperf-controller"
    product = "keysight-cyperf"
    publisher = "keysighttechnologies_cyperf"
  }

  source_image_reference {
    publisher = "keysighttechnologies_cyperf"
    offer     = "keysight-cyperf"
    sku       = "keysight-cyperf-controller"
    version   = var.cyperf_version
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_client_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_mdw
  ]
  name                = local.client_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_agent_machine_type
  admin_username      = "cyperf"
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_1_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_1_test_nic.id
  ]
  proximity_placement_group_id = azurerm_proximity_placement_group.azr_proximity_placement.id

  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  plan {
    name = "keysight-cyperf-agent"
    product = "keysight-cyperf"
    publisher = "keysighttechnologies_cyperf"
  }

  source_image_reference {
    publisher = "keysighttechnologies_cyperf"
    offer     = "keysight-cyperf"
    sku       = "keysight-cyperf-agent"
    version   = var.cyperf_version
  }

  custom_data = base64encode(local.custom_data)
}

resource "google_compute_network" "gcp_mgmt_vpc_network" {
  name                    = "${local.deployment_name}-${local.gcp_mgmt_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "gcp_mgmt_subnet" {
  name                     = "${local.deployment_name}-${local.gcp_mgmt_subnet_name}"
  ip_cidr_range            = local.gcp_mgmt_subnet_ip_range
  network                  = google_compute_network.gcp_mgmt_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}

resource "google_compute_firewall" "gcp_mgmt_firewall_rule" {
  name = "${local.deployment_name}-${local.gcp_mgmt_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_mgmt_firewall_rule_direction
  network       = google_compute_network.gcp_mgmt_vpc_network.self_link
  priority      = local.gcp_mgmt_firewall_rule_priority
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcp_nats_https_server" {
  name     = "${local.deployment_name}-nats-https-server"
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
  name                    = "${local.deployment_name}-${local.gcp_test_vpc_network_name}"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "gcp_test_subnet" {
  name                     = "${local.deployment_name}-${local.gcp_test_subnet_name}"
  ip_cidr_range            = local.gcp_test_subnet_ip_range
  network                  = google_compute_network.gcp_test_vpc_network.self_link
  region                   = local.gcp_region_name
  private_ip_google_access = true
}


resource "google_compute_firewall" "gcp_test_firewall_rule" {
  name = "${local.deployment_name}-${local.gcp_test_firewall_rule_name}"
  allow {
    protocol = "all"
  }
  direction     = local.gcp_test_firewall_rule_direction
  network       = google_compute_network.gcp_test_vpc_network.self_link
  priority      = local.gcp_test_firewall_rule_priority
  source_ranges = local.gcp_test_firewall_rule_source_ip_ranges
}

resource "google_compute_address" "gcp_nats_ip" {
  name = "${local.deployment_name}-broker-ip"
}

resource "google_compute_instance" "gcp_nats_instance" {
  name                      = "${local.deployment_name}-${local.gcp_nats_instance_name}"
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
    Owner              = local.deployment_name
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = "true"
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }

  labels = {
    owner   = replace(replace(local.deployment_name, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
}

resource "google_compute_instance" "gcp_server_agent_instance" {
  name                      = "${local.deployment_name}-${local.gcp_server_agent_instance_name}"
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
    Owner              = local.deployment_name
    Project            = local.gcp_project_tag
    Options            = local.gcp_options_tag
    serial-port-enable = local.gcp_agent_serial_port_enable
    ssh-keys           = "cyperf:${file(local.gcp_ssh_key)}"
  }
  labels = {
    owner   = replace(replace(local.deployment_name, ".", "-"), "@", "-")
    project = lower(local.gcp_project_tag)
    options = lower(local.gcp_options_tag)
  }
  tags = [ "gcp-agent" ]
}

output "mdw_detail" {
  value = {
    "name": azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip": azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip": azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address
  }
}

output "broker_public_ip" {
  value = google_compute_instance.gcp_nats_instance.network_interface.0.access_config.0.nat_ip
}

output "agents_detail"{
  value = [
  {
    "name": azurerm_linux_virtual_machine.azr_automation_client_agent.name,
    "management_private_ip": azurerm_linux_virtual_machine.azr_automation_client_agent.private_ip_address,
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_client_agent.public_ip_address
  },
  {
    "name": google_compute_instance.gcp_server_agent_instance.name,
    "management_private_ip": google_compute_instance.gcp_server_agent_instance.network_interface.0.network_ip,
    "management_public_ip": google_compute_instance.gcp_server_agent_instance.network_interface.0.access_config.0.nat_ip
  }   
  ]
}
