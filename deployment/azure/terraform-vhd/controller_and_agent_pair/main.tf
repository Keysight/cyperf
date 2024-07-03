provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

locals {
  mdw_name              = "${var.azure_owner_tag}-mdw-${var.mdw_name}"
  client_name           = "${var.azure_owner_tag}-client-${var.agent_name}"
  server_name           = "${var.azure_owner_tag}-server-${var.agent_name}"
  custom_data           = <<-CUSTOM_DATA
      #!/bin/bash
      bash /usr/bin/image_init_azure.sh  ${azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address}  --username "${var.controller_username}" --password "${var.controller_password}" --fingerprint "">> /home/cyperf/azure_image_init_log
      CUSTOM_DATA
  mgmt_iprange          = ["10.0.1.0/24", "fd00:10::/64"]
  test_iprange          = ["10.0.2.0/24"]
  client_test_static_ip = "10.0.2.4"
  server_test_static_ip = "10.0.2.5"
  sku                   = length(regexall("D48", var.azure_agent_machine_type)) >= 1 ? "A8" : "A4"
}

resource "azurerm_image" "controller" {
  name                = "cyperf-controller"
  location            = var.azure_region_name
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
  location            = var.azure_region_name
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

resource "azurerm_network_security_group" "azr_automation_nsg" {
  name                = "${var.azure_owner_tag}-sg"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name
  security_rule {
    name                         = "${var.azure_owner_tag}-ipv4-ixia-access-inbound"
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
  depends_on                = [azurerm_linux_virtual_machine.azr_automation_mdw, azurerm_linux_virtual_machine.azr_automation_client_agent, azurerm_linux_virtual_machine.azr_automation_server_agent]
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

resource "azurerm_subnet" "azr_automation_test_network" {
  name                 = "${var.azure_owner_tag}-test-subnet"
  resource_group_name  = azurerm_resource_group.azr_automation.name
  virtual_network_name = azurerm_virtual_network.azr_automation.name
  address_prefixes     = local.test_iprange
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

resource "azurerm_public_ip" "azr_automation_agent_1_public_ipv4" {
  count               = var.stack_type == "ipv6" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-agent1-public-ipv4"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "azr_automation_agent_1_public_ipv6" {
  count               = var.stack_type == "ipv4" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-agent1-public-ipv6"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Static"
  ip_version          = "IPv6"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "azr_automation_agent_2_public_ipv4" {
  count               = var.stack_type == "ipv6" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-agent2-public-ipv4"
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "azr_automation_agent_2_public_ipv6" {
  count               = var.stack_type == "ipv4" ? 0 : 1
  name                = "${var.azure_owner_tag}-cyperf-agent2-public-ipv6"
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

resource "azurerm_network_interface" "azr_automation_agent_1_mng_nic" {
  name                = "${var.azure_owner_tag}-agent-1-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-agent-1-management-private-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [] : [1]
    content {
      name                          = "${var.azure_owner_tag}-agent-1-management-public-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ipv4[0].id
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type != "ipv4" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-agent-1-management-ipv6"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_1_public_ipv6[0].id
      private_ip_address_version    = "IPv6"
    }
  }
}

resource "azurerm_network_interface" "azr_automation_agent_1_test_nic" {
  name                          = "${var.azure_owner_tag}-agent-1-test-nic"
  location                      = azurerm_resource_group.azr_automation.location
  resource_group_name           = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  enable_ip_forwarding          = true
  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-1-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_test_network.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.client_test_static_ip
  }
  tags = {
    fastpathenabled = var.accelerated_connections == "enable" ? true : false
  }
  auxiliary_mode = var.accelerated_connections == "enable" ? "AcceleratedConnections" : null
  auxiliary_sku  = var.accelerated_connections == "enable" ? local.sku : null
}

resource "azurerm_network_interface" "azr_automation_agent_2_mng_nic" {
  name                = "${var.azure_owner_tag}-agent-2-management-nic"
  location            = azurerm_resource_group.azr_automation.location
  resource_group_name = azurerm_resource_group.azr_automation.name

  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-agent-2-management-private-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
  dynamic "ip_configuration" {
    for_each = var.stack_type == "ipv6" ? [] : [1]
    content {
      name                          = "${var.azure_owner_tag}-agent-2-management-public-ipv4"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_2_public_ipv4[0].id
      primary                       = true
    }
  }

  dynamic "ip_configuration" {
    for_each = var.stack_type != "ipv4" ? [1] : []
    content {
      name                          = "${var.azure_owner_tag}-agent-2-management-ipv6"
      subnet_id                     = azurerm_subnet.azr_automation_management_network.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.azr_automation_agent_2_public_ipv6[0].id
      private_ip_address_version    = "IPv6"
    }
  }
}

resource "azurerm_network_interface" "azr_automation_agent_2_test_nic" {
  name                          = "${var.azure_owner_tag}-agent-2-test-nic"
  location                      = azurerm_resource_group.azr_automation.location
  resource_group_name           = azurerm_resource_group.azr_automation.name
  enable_accelerated_networking = true
  enable_ip_forwarding          = true
  ip_configuration {
    name                          = "${var.azure_owner_tag}-agent-2-test-ip"
    subnet_id                     = azurerm_subnet.azr_automation_test_network.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.server_test_static_ip
  }
  tags = {
    fastpathenabled = var.accelerated_connections == "enable" ? true : false
  }
  auxiliary_mode = var.accelerated_connections == "enable" ? "AcceleratedConnections" : null
  auxiliary_sku  = var.accelerated_connections == "enable" ? local.sku : null
}

resource "azurerm_linux_virtual_machine" "azr_automation_mdw" {
  name                = local.mdw_name
  resource_group_name = azurerm_resource_group.azr_automation.name
  location            = azurerm_resource_group.azr_automation.location
  size                = var.azure_mdw_machine_type
  source_image_id     = azurerm_image.controller.id
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
    storage_account_type = "StandardSSD_LRS"
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
  source_image_id     = azurerm_image.agent.id
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
    storage_account_type = "StandardSSD_LRS"
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
  size                = var.azure_agent_machine_type
  admin_username      = var.azure_admin_username
  source_image_id     = azurerm_image.agent.id
  network_interface_ids = [
    azurerm_network_interface.azr_automation_agent_2_mng_nic.id,
    azurerm_network_interface.azr_automation_agent_2_test_nic.id
  ]
  proximity_placement_group_id = azurerm_proximity_placement_group.azr_proximity_placement.id

  admin_ssh_key {
    username   = "cyperf"
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  custom_data = base64encode(local.custom_data)
}
resource "azurerm_route_table" "er_route" {
  name                          = "${var.azure_owner_tag}-ER-route"
  location                      = azurerm_resource_group.azr_automation.location
  resource_group_name           = azurerm_resource_group.azr_automation.name
  disable_bgp_route_propagation = false
  route {
    name                   = "${var.azure_owner_tag}-client-server"
    address_prefix         = var.server_IP_stack_range
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.azr_automation_agent_2_test_nic.private_ip_address
  }
  route {
    name                   = "${var.azure_owner_tag}-server-client"
    address_prefix         = var.client_IP_stack_range
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.azr_automation_agent_1_test_nic.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "associate_subnet_to_route" {
  subnet_id      = azurerm_subnet.azr_automation_test_network.id
  route_table_id = azurerm_route_table.er_route.id
}

output "mdw_detail" {
  value = {
    "name" : azurerm_linux_virtual_machine.azr_automation_mdw.name,
    "private_ip" : azurerm_linux_virtual_machine.azr_automation_mdw.private_ip_address,
    "public_ip" : azurerm_linux_virtual_machine.azr_automation_mdw.public_ip_address,
    "type" : "azure"
  }
}

output "agents_detail" {
  value = [
    {
      "name" : azurerm_linux_virtual_machine.azr_automation_client_agent.name,
      "management_private_ip" : azurerm_linux_virtual_machine.azr_automation_client_agent.private_ip_address,
      "management_public_ip" : azurerm_linux_virtual_machine.azr_automation_client_agent.public_ip_address,
      "type" : "azure"
    },
    {
      "name" : azurerm_linux_virtual_machine.azr_automation_server_agent.name,
      "management_private_ip" : azurerm_linux_virtual_machine.azr_automation_server_agent.private_ip_address,
      "management_public_ip" : azurerm_linux_virtual_machine.azr_automation_server_agent.public_ip_address,
      "type" : "azure"
    }
  ]
}
