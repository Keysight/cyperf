module "App" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-cyperf-app.git?ref=5.0.0"
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	ResourceGroupLocation = data.azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = data.azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AppVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey
	]
}

module "Agent1" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-cyperf-agent.git?ref=5.0.0"
	AppEth0IpAddress = module.App.Instance.private_ip_address
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	Eth1SubnetId = data.azurerm_subnet.PrivateSubnet.id
	InstanceId = local.Agent1InstanceId
	ResourceGroupLocation = data.azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = data.azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AgentVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.App
	]
}

module "Agent2" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-cyperf-agent.git?ref=5.0.0"
	AppEth0IpAddress = module.App.Instance.private_ip_address
	Eth0IpAddress = local.Agent2Eth0IpAddress
	Eth0SubnetId = data.azurerm_subnet.PublicSubnet.id
	Eth1IpAddresses = local.Agent2Eth1IpAddresses
	Eth1SubnetId = data.azurerm_subnet.PrivateSubnet.id
	InstanceId = local.Agent2InstanceId
	ResourceGroupLocation = data.azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = data.azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AgentVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.App
	]
}

resource "random_id" "RandomId" {
	byte_length = 4
}