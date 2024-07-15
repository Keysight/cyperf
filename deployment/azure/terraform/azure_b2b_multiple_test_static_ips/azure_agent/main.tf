locals {
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      bash /usr/bin/image_init_azure.sh  ${var.controller_ip} --username "${var.username}" --password "${var.password}" --fingerprint "">> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  split_version = split(".", var.agent_version)
  sku_name_agent = var.agent_version != "0.2.0" ? "keysight-cyperf-agent-${local.split_version[1]}${local.split_version[2]}" : "keysight-cyperf-agent"
}

resource "azurerm_public_ip" "agent_mgmt_public_ip" {
  name                = "${var.azure_agent_name}-mgmt-public-ip"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  allocation_method   = "Dynamic"
  tags = {
    owner = var.azure_owner
  }
}

resource "azurerm_network_interface" "azr_automation_agent_mng_nic" {
  name                = "${var.azure_agent_name}-mgmt-nic"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  ip_configuration {
    name                          = "${var.azure_agent_name}-management-ip"
    subnet_id                     = var.mgmt_subnet
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_mgmt_public_ip.id
  }
  tags = {
    owner = var.azure_owner
  }
}

resource "azurerm_network_interface" "azr_automation_agent_test_nic" {
  name                = "${var.azure_agent_name}-test-nic"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  accelerated_networking_enabled = true
  ip_configuration  {
    name                          = "${var.azure_agent_name}-test-ip-1"
    subnet_id                     = var.test_subnet
    private_ip_address_allocation = "Static"
    primary = true
    private_ip_address            = "${var.test_ip_start}1"
  }
  ip_configuration  {
    name                          = "${var.azure_agent_name}-test-ip-2"
    subnet_id                     = var.test_subnet
    private_ip_address_allocation = "Static"
    primary = false
    private_ip_address            = "${var.test_ip_start}2"
  }
  ip_configuration  {
    name                          = "${var.azure_agent_name}-test-ip-3"
    subnet_id                     = var.test_subnet
    private_ip_address_allocation = "Static"
    primary = false
    private_ip_address            = "${var.test_ip_start}3"
  }
  tags = {
    owner = var.azure_owner
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_agent" {
  name                = var.azure_agent_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = var.azure_agent_machine_type
  admin_username      = "cyperf"
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

  plan {
    name = local.sku_name_agent
    product = "keysight-cyperf"
    publisher = "keysighttechnologies_cyperf"
  }

  source_image_reference {
    publisher = "keysighttechnologies_cyperf"
    offer     = "keysight-cyperf"
    sku       = local.sku_name_agent
    version   = var.agent_version
  }

  custom_data = base64encode(local.custom_data)
  tags = {
    owner = var.azure_owner
    role = var.agent_role
  }
}