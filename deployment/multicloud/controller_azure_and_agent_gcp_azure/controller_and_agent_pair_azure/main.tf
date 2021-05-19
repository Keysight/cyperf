provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}

data "azurerm_resource_group" "azr_automation" {
  name     = var.DEST_azure_owner_tag
}

data "azurerm_subnet" "azr_automation_management_network" {
  name                 = var.MANAGEMENT_SUBNET_NAME
  resource_group_name  = data.azurerm_resource_group.azr_automation.name
  virtual_network_name = var.VIRTUAL_NETWORK_NAME
}

data "azurerm_subnet" "azr_automation_test_network" {
  name                 = var.TEST_SUBNET_NAME
  resource_group_name  = data.azurerm_resource_group.azr_automation.name
  virtual_network_name = var.VIRTUAL_NETWORK_NAME
}

resource "azurerm_image" "agent_image" {
  name                = var.agent_version
  location            = var.azure_region_name
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.AGENT_BLOB_URI
  }
}

resource "azurerm_image" "mdw_image" {
  name                = var.mdw_version
  location            = var.azure_region_name
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.MDW_BLOB_URI
  }
}

resource "azurerm_network_security_group" "azr_automation" {
  name                = "${var.azure_owner_tag}-sg"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name
    security_rule {
    name                       = var.azure_owner_tag
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

resource "azurerm_public_ip" "azr_automation_mdw_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-mdw-public-ip"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_1_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent1-public-ip"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_2_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent2-public-ip"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_1_test_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent1-test-public-ip"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "azr_automation_agent_2_test_public_ip" {
  name                = "${var.azure_owner_tag}-cyperf-agent2-test-public-ip"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azr_automation_mdw_nic" {
  name                = "${var.azure_owner_tag}-mdw-management-nic"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-mdw-ip"
    subnet_id                     = data.azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_mdw_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_mng_nic" {
  name                = "${var.azure_owner_tag}-agent-1-management-nic"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-1-management-ip"
    subnet_id                     = data.azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_test_nic" {
  name                = "${var.azure_owner_tag}-agent-1-test-nic"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-1-test-ip"
    subnet_id                     = data.azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_test_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_2_mng_nic" {
  name                = "${var.azure_owner_tag}-agent-2-management-nic"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-2-management-ip"
    subnet_id                     = data.azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_2_public_ip.id
  }
}

resource "azurerm_network_interface" "azr_automation_agent_2_test_nic" {
  name                = "${var.azure_owner_tag}-agent-2-test-nic"
  location            = data.azurerm_resource_group.azr_automation.location
  resource_group_name = data.azurerm_resource_group.azr_automation.name

  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-2-test-ip"
    subnet_id                     = data.azurerm_subnet.azr_automation_management_network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azr_automation_agent_2_test_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = "${var.azure_owner_tag}-cyperf-mdw"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  size                = var.azure_mdw_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.mdw_image.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_mdw_nic.id,
  ]

  admin_ssh_key {
    username   = var.azure_admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_agent_1" {
  name                = "${var.azure_owner_tag}-cyperf-agent-1"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  size                = var.azure_agent_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.agent_image.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_1_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_1_test_nic.id
  ]

  admin_ssh_key {
    username   = var.azure_admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "azr_automation_agent_2" {
  name                = "${var.azure_owner_tag}-cyperf-agent-2"
  resource_group_name = data.azurerm_resource_group.azr_automation.name
  location            = data.azurerm_resource_group.azr_automation.location
  size                = var.azure_agent_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.agent_image.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_2_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_2_test_nic.id
  ]

  admin_ssh_key {
    username   = var.azure_admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "null_resource" "agent_1_executer" {
  depends_on = [azurerm_linux_virtual_machine.azr_automation_agent_1]
  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.azr_automation_agent_1.public_ip_address
    user        = var.azure_admin_username
    private_key = file(var.ssh_private_key_path)
  }

 provisioner "remote-exec" {
    inline = [
      "/bin/bash /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address} >> /home/cyperf/azure_image_init_log"
    ]
  }
}

resource "null_resource" "agent_2_executer" {
  depends_on = [azurerm_linux_virtual_machine.azr_automation_agent_2]
  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.azr_automation_agent_2.public_ip_address
    user        = var.azure_admin_username
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address} >> /home/cyperf/azure_image_init_log"
    ]
  }
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
    "name": azurerm_linux_virtual_machine.azr_automation_agent_1.name,
    "management_private_ip": azurerm_linux_virtual_machine.azr_automation_agent_1.private_ip_address,
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_agent_1.public_ip_address
  },
  {
    "name": azurerm_linux_virtual_machine.azr_automation_agent_2.name,
    "management_private_ip": azurerm_linux_virtual_machine.azr_automation_agent_2.private_ip_address,
    "management_public_ip": azurerm_linux_virtual_machine.azr_automation_agent_2.public_ip_address
  }
  ]
}

output "images_details" {
  value = {
    "mdw_id": azurerm_image.mdw_image.id,
    "mdw_name": azurerm_image.mdw_image.name,
    "agent_id": azurerm_image.agent_image.id,
    "agent_name": azurerm_image.agent_image.name
  }
}