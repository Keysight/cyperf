module "Agent1" {
	source = "armdupre/module-ubuntu-linux-agent/azurerm"
	version = "22.0.4"
	Eth0SubnetId = module.Vnet.PublicSubnet.id
	Eth1IpAddresses = local.Agent1Eth1IpAddresses
	Eth1SubnetId = module.Vnet.PrivateSubnet.id
	InstanceId = local.Agent1InstanceId
	ResourceGroupLocation = azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AgentVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.Vnet
	]
}

module "Agent2" {
	source = "armdupre/module-ubuntu-linux-agent/azurerm"
	version = "22.0.4"
	Eth0IpAddress = local.Agent2Eth0IpAddress
	Eth0SubnetId = module.Vnet.PublicSubnet.id
	Eth1IpAddresses = local.Agent2Eth1IpAddresses
	Eth1SubnetId = module.Vnet.PrivateSubnet.id
	InstanceId = local.Agent2InstanceId
	ResourceGroupLocation = azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AgentVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.Vnet
	]
}

resource "azurerm_resource_group" "ResourceGroup" {
	name = local.ResourceGroupName
	location = local.ResourceGroupLocation
}