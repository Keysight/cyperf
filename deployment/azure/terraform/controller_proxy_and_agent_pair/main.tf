provider "azurerm" {
  features {
    
  }

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

locals {
  broker_name = "${var.azure_owner_tag}-broker-${var.broker_image}"
  client_name = "${var.azure_owner_tag}-client-${var.agent_version}"
  server_name = "${var.azure_owner_tag}-server-${var.agent_version}"
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_nats_broker.private_ip_address} >> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  mgmt_iprange = ["10.0.1.0/24"]
  test_iprange = ["10.0.2.0/24"]
  firewall_ip_range = var.azure_allowed_cidr
}

resource "azurerm_image" "controller_proxy" {
  name                = "cyperf-controller-proxy"
  location = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  hyper_v_generation  = "V1"
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.controller_proxy_image
  }
}

resource "azurerm_image" "agent" {
  name                = "cyperf-agent"
  location = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  hyper_v_generation  = "V1"
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.agent_image
  }
}

resource "azurerm_resource_group" "azr_automation" {
  name     = var.azure_owner_tag
  location = var.azure_region_name
}

resource "azurerm_network_security_group" "azr_automation_nsg" {
  name                = "${var.azure_owner_tag}-sg"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  security_rule {
    name                       = "${var.azure_owner_tag}-generic-access-inbound"
    priority                   = 999
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = local.firewall_ip_range
    destination_address_prefixes = local.firewall_ip_range
  }
  security_rule {
    name                       = "${var.azure_owner_tag}-generic-access-outbound"
    priority                   = 999
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = local.firewall_ip_range
    destination_address_prefixes = local.firewall_ip_range
  }
  security_rule {
    name                       = "${var.azure_owner_tag}-deny-public-access"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "azr_automation" {
  name                = "${var.azure_owner_tag}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
}

resource "azurerm_subnet" "azr_automation_management_network" {
  name                 = "${var.azure_owner_tag}-management-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = local.mgmt_iprange
}

resource "azurerm_subnet" "azr_automation_test_network" {
  name                 = "${var.azure_owner_tag}-test-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = local.test_iprange
}

resource "azurerm_public_ip" "azr_automation_client_agent_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent1-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_client_agent_test_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent1-test-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_client_agent_test_nic" {
  name                = "${var.azure_owner_tag}-client-agent-test-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "${var.azure_owner_tag}-client_agent-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_client_agent_test_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_client_agent_mng_nic" {
  name                = "${var.azure_owner_tag}-client-agent-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-client-agent-management-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_client_agent_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_client_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_nats_broker,
    azurerm_image.agent
  ]
  name                = local.client_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_agent_machine_type
  admin_username      = "cyperf"
  source_image_id     = azurerm_image.agent.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_client_agent_mng_nic.id,
    azurerm_network_interface.azr_automation_client_agent_test_nic.id
  ]
  tags = {
    "name" = "azure-client"
  }
  custom_data = base64encode(local.custom_data)
  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_public_ip" "azr_automation_agent_server_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent-server-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_server_test_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent-server-test-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_agent_server_mng_nic" {
  name                = "${var.azure_owner_tag}-agent-server-1-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-server-management-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_server_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_server_test_nic" {
  name                = "${var.azure_owner_tag}-agent-server-test-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-server-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_server_test_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_server_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_nats_broker,
    azurerm_image.agent
  ]
  name                = local.server_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_agent_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.agent.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_server_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_server_test_nic.id
  ]
  tags = {
    "name" = "azure-server"
  }
  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }
  custom_data = base64encode(local.custom_data)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_public_ip" "azr_automation_nats_broker_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-nats-broker-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_nats_broker_nic" {
  name                = local.broker_name
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-nats-broker-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_nats_broker_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_nats_broker" {
  name                = "${var.azure_owner_tag}-cyperf-nats"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_broker_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.controller_proxy.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_nats_broker_nic.id
  ]
  tags = {
    "name" = "azure-agents"
  }
  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

output "broker_public_ip" {
  value = azurerm_linux_virtual_machine.azr_automation_nats_broker.public_ip_address
}

output "agents_detail"{
  value = [
 {
    "name": azurerm_linux_virtual_machine.azr_automation_client_agent.name,
    "management_private_ip": azurerm_linux_virtual_machine.azr_automation_client_agent.private_ip_address,
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_client_agent.public_ip_address
  },
  {
    "name": azurerm_linux_virtual_machine.azr_automation_server_agent.name,
    "management_private_ip": azurerm_linux_virtual_machine.azr_automation_server_agent.private_ip_address,
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_server_agent.public_ip_address
  }
  ]
}