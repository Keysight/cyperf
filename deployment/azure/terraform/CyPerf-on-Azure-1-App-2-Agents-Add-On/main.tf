module "App" {
	source = "armdupre/module-cyperf-app/azurerm"
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	ResourceGroupLocation = local.ResourceGroupLocation
	ResourceGroupName = local.ResourceGroupName
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	VmSize = local.AppVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey
	]
}

module "Agent1" {
	source = "armdupre/module-cyperf-agent/azurerm"
	AppEth0IpAddress = module.App.Instance.private_ip_address
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	Eth1SubnetId = data.azurerm_subnet.PrivateSubnet.id
	InstanceId = local.Agent1InstanceId
	ResourceGroupLocation = local.ResourceGroupLocation
	ResourceGroupName = local.ResourceGroupName
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	VmSize = local.AgentVmSize
	depends_on = [
		module.App,
		azurerm_ssh_public_key.SshKey
	]
}

module "Agent2" {
	source = "armdupre/module-cyperf-agent/azurerm"
	AppEth0IpAddress = module.App.Instance.private_ip_address
	Eth0IpAddress = local.Agent2Eth0IpAddress
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	Eth1IpAddresses = local.Agent2Eth1IpAddresses
	Eth1SubnetId = data.azurerm_subnet.PrivateSubnet.id
	InstanceId = local.Agent2InstanceId
	ResourceGroupLocation = local.ResourceGroupLocation
	ResourceGroupName = local.ResourceGroupName
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	VmSize = local.AgentVmSize
	depends_on = [
		module.App,
		azurerm_ssh_public_key.SshKey
	]
}