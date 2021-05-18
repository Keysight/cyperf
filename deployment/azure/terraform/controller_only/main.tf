provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

locals {
  mdw_name = "${var.AZURE_OWNER_TAG}-mdw-${var.mdw_version}"
}

resource "azurerm_resource_group" "azr_automation" {
  name     = var.AZURE_OWNER_TAG
  location = var.AZURE_REGION_NAME
}

resource "azurerm_network_security_group" "azr_automation" {
  name                = "${var.AZURE_OWNER_TAG}-sg"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
    security_rule {
    name                       = var.AZURE_OWNER_TAG
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
  name                = "${var.AZURE_OWNER_TAG}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
}

resource "azurerm_subnet" "azr_automation_management_network" {
  name                 = "${var.AZURE_OWNER_TAG}-management-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "azr_automation_mdw_public_ip" {
  name                = "${var.AZURE_OWNER_TAG}-cyperf-mdw-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_mdw_nic" {
  name                = "${var.AZURE_OWNER_TAG}-mdw-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.AZURE_OWNER_TAG}-mdw-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = local.mdw_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.AZURE_MDW_MACHINE_TYPE
  admin_username      = "cyperf"
  source_image_id     = var.controller_image
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
}

output "mdw_detail" {
  value = {
    "name": azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip": azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip": azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address
  }
}
