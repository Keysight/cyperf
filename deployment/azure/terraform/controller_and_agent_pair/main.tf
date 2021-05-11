provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

locals {
  mdw_name = "${var.AZURE_OWNER_TAG}-mdw-${var.mdw_version}"
  client_name = "${var.AZURE_OWNER_TAG}-client-${var.agent_version}"
  server_name = "${var.AZURE_OWNER_TAG}-server-${var.agent_version}"
  custom_data = <<-CUSTOM_DATA
      #!/bin/bash
      /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address} >> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  
}

resource "azurerm_resource_group" "azr_automation" {
  name     = var.AZURE_OWNER_TAG
  location = var.AZURE_REGION_NAME
}

resource "azurerm_proximity_placement_group" "azr_proximity_placement" {
  name                = "${var.AZURE_OWNER_TAG}-proximity-placement"
  location            = var.AZURE_REGION_NAME
  resource_group_name = azurerm_resource_group.azr_automation.name

  tags = {
    environment = "test-enviroment"
  }
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

resource "azurerm_subnet" "azr_automation_test_network" {
  name                 = "${var.AZURE_OWNER_TAG}-test-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "azr_automation_mdw_public_ip" {
  name                = "${var.AZURE_OWNER_TAG}-cyperf-mdw-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_1_public_ip" {
  name                = "${var.AZURE_OWNER_TAG}-cyperf-agent1-public-ip"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_2_public_ip" {
  name                = "${var.AZURE_OWNER_TAG}-cyperf-agent2-public-ip"
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

resource "azurerm_network_interface" "azr_automation_agent_1_mng_nic" {
  name                = "${var.AZURE_OWNER_TAG}-agent-1-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.AZURE_OWNER_TAG}-agent-1-management-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_test_nic" {
  name                = "${var.AZURE_OWNER_TAG}-agent-1-test-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "${var.AZURE_OWNER_TAG}-agent-1-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_test_network.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "azr_automation_agent_2_mng_nic" {
  name                = "${var.AZURE_OWNER_TAG}-agent-2-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.AZURE_OWNER_TAG}-agent-2-management-ip"
    subnet_id                     = azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_2_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_2_test_nic" {
  name                = "${var.AZURE_OWNER_TAG}-agent-2-test-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "${var.AZURE_OWNER_TAG}-agent-2-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_test_network.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = local.mdw_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.AZURE_MDW_MACHINE_TYPE
  admin_username      = "cyperf"
  source_image_id     = "/subscriptions/908fce0d-1b5e-475a-a419-2a30b8c01f6b/resourceGroups/cyperf-mdw-images/providers/Microsoft.Compute/images/cyperf-mdw-v${var.mdw_version}"
  network_interface_ids = [
    azurerm_network_interface.azr_automation_mdw_nic.id,
  ]

  admin_ssh_key {
    username   = "cyperf"
    public_key = file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_client_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_mdw
  ]
  name                = local.client_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.AZURE_AGENT_MACHINE_TYPE
  admin_username      = "cyperf"
  source_image_id     = "/subscriptions/908fce0d-1b5e-475a-a419-2a30b8c01f6b/resourceGroups/CM_ResourceGroup/providers/Microsoft.Compute/images/cyperf-agent-${var.agent_version}"
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_1_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_1_test_nic.id
  ]
  proximity_placement_group_id = azurerm_proximity_placement_group.azr_proximity_placement.id

  admin_ssh_key {
    username   = "cyperf"
    public_key = file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(local.custom_data)
}

resource "azurerm_linux_virtual_machine" "azr_automation_server_agent" {
  depends_on = [
    azurerm_linux_virtual_machine.azr_automation_mdw
  ]
  name                = local.server_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.AZURE_AGENT_MACHINE_TYPE
  admin_username      = var.AZURE_ADMIN_USERNAME
  source_image_id     = "/subscriptions/908fce0d-1b5e-475a-a419-2a30b8c01f6b/resourceGroups/CM_ResourceGroup/providers/Microsoft.Compute/images/cyperf-agent-${var.agent_version}"
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_2_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_2_test_nic.id
  ]
  proximity_placement_group_id = azurerm_proximity_placement_group.azr_proximity_placement.id
  
  admin_ssh_key {
    username   = "cyperf"
    public_key = file("/var/lib/jenkins/appsec/resources/ssh_keys/id_rsa_ghost.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  custom_data = base64encode(local.custom_data)
}

output "mdw_detail" {
  value = {
    "name": azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip": azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip": azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address
  }
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
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_server_agent.public_ip_address,
  }
  ]
}
