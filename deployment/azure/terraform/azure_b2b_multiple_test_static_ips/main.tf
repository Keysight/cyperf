provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

locals {
  mdw_name = "${var.azure_owner_tag}-mdw-${var.mdw_version}"
  client_name = "${var.azure_owner_tag}-client-${var.agent_version}"
  server_name = "${var.azure_owner_tag}-server-${var.agent_version}"
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address} >> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  vpc_address_space = ["10.0.0.0/16"]
  mgmt_iprange = ["10.0.1.0/24"]
  test_iprange = ["10.0.2.0/24"]
  firewall_ip_range = concat(var.azure_allowed_cidr,local.mgmt_iprange,local.test_iprange)
}

resource "azurerm_image" "controller" {
  name                = "cyperf-controller"
  location = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  hyper_v_generation  = "V1"
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.controller_image
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

resource "azurerm_proximity_placement_group" "azr_proximity_placement" {
  name                = "${var.azure_owner_tag}-proximity-placement"
  location            = var.azure_region_name
  resource_group_name = azurerm_resource_group.azr_automation.name

  tags = {
    environment = "test-enviroment"
  }
}

resource "azurerm_virtual_network" "azr_automation" {
  name                = "${var.azure_owner_tag}-network"
  address_space       = local.vpc_address_space
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

resource "azurerm_public_ip" "azr_automation_mdw_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-mdw-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
  tags = {
    owner = var.azure_owner_tag
  }
}

resource "azurerm_network_interface" "azr_automation_mdw_nic" {
  name                = "${var.azure_owner_tag}-mdw-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-mdw-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ip.id
  }
  tags = {
    owner = var.azure_owner_tag
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
    storage_account_type = "Standard_LRS"
  }
  tags = {
    owner = var.azure_owner_tag
  }
}

module "agents" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_mdw
  ]
  count = var.agents
  source = "./azure_agent"
  azure_agent_name = "${var.azure_owner_tag}-agent-${count.index}"
  azure_owner = var.azure_owner_tag
  resource_group = azurerm_resource_group.azr_automation
  mgmt_subnet = azurerm_subnet.azr_automation_management_network.id
  test_subnet = azurerm_subnet.azr_automation_test_network.id
  controller_ip = azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address
  agent_version = azurerm_image.agent.id
  azure_agent_machine_type = var.azure_agent_machine_type
  public_key = var.public_key
  agent_role = "azure"
  /*Currently hashicorp/azurerm v2.70.0.. does not let us create ip configuration
  with loop or for each syntax. This unfortunately limits the dynamic specification
  of ip configuration. You can modify the azure agent module to add or remove ip
  configuration*/
  test_ip_start = "10.0.2.${count.index+1}"
}


output "mdw_detail" {
  value = {
    "name": azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip": azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip": azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address
  }
}

output "agents_detail"{
  value = [for x in module.agents :   {
    "name" : x.name,
    "public_ip" : x.public_ip,
    "private_ip" : x.private_ip
  }]
}
