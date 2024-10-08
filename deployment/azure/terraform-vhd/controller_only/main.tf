provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

locals {
  mdw_name     = "${var.azure_owner_tag}-mdw-${var.mdw_name}"
  mgmt_iprange = ["10.0.1.0/24", "fd00:10::/64"]
}

resource "azurerm_image" "controller" {
  name                = "cyperf-controller"
  location            = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  hyper_v_generation  = "V1"
  os_disk {
    storage_type = "StandardSSD_LRS"
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.controller_image
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
    name                         = "${var.azure_owner_tag}-generic-access-inbound"
    priority                     = 999
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = var.azure_allowed_cidr_ipv4
    destination_address_prefixes = var.azure_allowed_cidr_ipv4
  }
  security_rule {
    name                         = "${var.azure_owner_tag}-ipv6-ixia-access-inbound"
    priority                     = 998
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = var.azure_allowed_cidr_ipv6
    destination_address_prefixes = var.azure_allowed_cidr_ipv6
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

resource "azurerm_subnet_network_security_group_association" "azr_mgmt_nsga" {
  depends_on                = [azurerm_linux_virtual_machine.azr_automation_mdw]
  subnet_id                 = azurerm_subnet.azr_automation_management_network.id
  network_security_group_id = azurerm_network_security_group.azr_automation_nsg.id
}

resource "azurerm_virtual_network" "azr_automation" {
  name                = "${var.azure_owner_tag}-network"
  address_space       = ["10.0.0.0/16", "fd00:10::/64"]
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
}

resource "azurerm_subnet" "azr_automation_management_network" {
  name                 = "${var.azure_owner_tag}-management-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = local.mgmt_iprange
}

resource "azurerm_public_ip" "azr_automation_mdw_public_ipv4" {
  count               = var.stack_type == "ipv6" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-mdw-public-ipv4"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "azr_automation_mdw_public_ipv6" {
  count               = var.stack_type == "ipv4" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-mdw-public-ipv6"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Static"
  ip_version          = "IPv6"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "azr_automation_mdw_nic" {
  name                = "${var.azure_owner_tag}-mdw-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-mdw-private-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [] : [1]
    content {
      name                          = "${var.azure_owner_tag}-mdw-public-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ipv4[0].id
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type != "ipv4" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-mdw-ipv6"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ipv6[0].id
      private_ip_address_version    = "IPv6"
    }
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = local.mdw_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_mdw_machine_type
  admin_username      = "cyperf"
  source_image_id     = azurerm_image.controller.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_mdw_nic.id,
  ]

  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
}

output "mdw_detail" {
  value = {
    "name" : azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip" : azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip" : azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address,
    "type" : "azure"
  }
}