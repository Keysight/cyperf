provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

locals {
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      bash /usr/bin/image_init_azure.sh  ${var.controller_ip} --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  instance_sku_map = {
    "Standard_F4s_v2"   = "A2"
    "Standard_F16s_v2"  = "A4"
    "Standard_D48s_v4"  = "A8"
    "Standard_D48_v4"   = "A8"
  }
  sku = lookup(local.instance_sku_map, var.azure_agent_machine_type)
  instance_storage_type ={
    "Standard_F4s_v2"   = "Premium_LRS"
    "Standard_F16s_v2"  = "Premium_LRS"
    "Standard_D48s_v4"  = "Premium_LRS"
    "Standard_D48_v4"   = "StandardSSD_LRS"
  }
  storage_type = lookup(local.instance_storage_type, var.azure_agent_machine_type)
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
  name                = "cyperf-agent-image"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  hyper_v_generation  = "V1"
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.agent_image
  }
}

resource "azurerm_public_ip" "azr_automation_agent_1_public_ipv4" {
  count               = var.stack_type == "ipv6" ? 0 : 1
  name                = "${var.azure_agent_name}-mgmt-public-ipv4"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "azr_automation_agent_1_public_ipv6" {
  count               = var.stack_type == "ipv4" ? 0 : 1
  name                = "${var.azure_agent_name}-mgmt-public-ipv6"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  ip_version          = "IPv6"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "azr_automation_agent_mng_nic" {
  name                = "${var.azure_agent_name}-mgmt-nic"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [1] : []
    content {
      name                          = "${var.azure_agent_name}-agent-management-private-ipv4"
      subnet_id                     = data.azurerm_subnet.mgmt_subnet.id
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [] : [1]
    content {
      name                          = "${var.azure_agent_name}-agent-management-public-ipv4"
      subnet_id                     = data.azurerm_subnet.mgmt_subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ipv4[0].id
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type != "ipv4" ? [1] : []
    content {
      name                          = "${var.azure_agent_name}-agent-management-ipv6"
      subnet_id                     = data.azurerm_subnet.mgmt_subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ipv6[0].id
      private_ip_address_version    = "IPv6"
    }
  }
}

resource "azurerm_network_interface" "azr_automation_agent_test_nic" {
  name                          = "${var.azure_agent_name}-test-nic"
  resource_group_name           = var.resource_group_name
  location                      = var.resource_group_location
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "${var.azure_agent_name}-test-ip-1"
    subnet_id                     = data.azurerm_subnet.test_subnet.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    fastpathenabled = var.accelerated_connections == "enable" ? true : false
  }
  auxiliary_mode = var.accelerated_connections == "enable" ? "AcceleratedConnections" : null
  auxiliary_sku  = var.accelerated_connections == "enable" ? local.sku : null
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
    storage_account_type = local.storage_type
  }

  custom_data = base64encode(local.custom_data)
  tags = {
    role = var.agent_role
  }
}
output "agents_detail" {
  value = [
    {
      "name" : azurerm_linux_virtual_machine.azr_automation_agent.name,
      "management_private_ip" : azurerm_linux_virtual_machine.azr_automation_agent.private_ip_address,
      "management_public_ip" : azurerm_linux_virtual_machine.azr_automation_agent.public_ip_address,
      "test_public_ip" : azurerm_linux_virtual_machine.azr_automation_agent.public_ip_addresses,
      "type" : "azure"
    }
  ]
}