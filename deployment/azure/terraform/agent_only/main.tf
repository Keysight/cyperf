provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

locals {
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      sh /usr/bin/image_init_azure.sh  ${var.controller_ip} >> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
}

data "azurerm_subnet" "mgmt_subnet" {
  name                 = var.mgmt_subnet
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

data "azurerm_subnet" "test_subnet" {
  name                 = var.test_subnet
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_image" "agent" {
  name     = "cyperf-agent-image"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  hyper_v_generation  = "V1"
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.agent_image
  }
}

resource "azurerm_public_ip" "agent_mgmt_public_ip" {
  name                = "${var.azure_agent_name}-mgmt-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_agent_mng_nic" {
  name                = "${var.azure_agent_name}-mgmt-nic"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  ip_configuration {
    name                          = "${var.azure_agent_name}-management-ip"
    subnet_id                     = data.azurerm_subnet.mgmt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_mgmt_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_test_nic" {
  name                = "${var.azure_agent_name}-test-nic"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  enable_accelerated_networking = true
  ip_configuration  {
    name                          = "${var.azure_agent_name}-test-ip-1"
    subnet_id                     = data.azurerm_subnet.test_subnet.id
    primary = true
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_agent" {
  name                = var.azure_agent_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = var.azure_agent_machine_type
  admin_username      = "cyperf"
  source_image_id     = azurerm_image.agent.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_test_nic.id
  ]

  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  custom_data = base64encode(local.custom_data)
  tags = {
    role = var.agent_role
  }
}