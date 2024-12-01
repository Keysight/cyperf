module "App" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-cyperf-app.git?ref=5.0.0"
	Eth0SubnetId = module.Vnet.PublicSubnet.id
	ResourceGroupLocation = azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AppVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.Vnet
	]
}

module "Agent1" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-cyperf-agent.git?ref=5.0.0"
	AppEth0IpAddress = module.App.Instance.private_ip_address
	Eth0SubnetId = module.Vnet.PublicSubnet.id
	Eth1SubnetId = module.Vnet.PrivateSubnet.id
	InstanceId = local.Agent1InstanceId
	ResourceGroupLocation = azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	SshKeyName = azurerm_ssh_public_key.SshKey.name
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	VmSize = local.AgentVmSize
	depends_on = [
		azurerm_ssh_public_key.SshKey,
		module.App,
		module.Vnet
	]
}

resource "azurerm_resource_group" "ResourceGroup" {
	name = local.ResourceGroupName
	location = local.ResourceGroupLocation
}

resource "random_id" "RandomId" {
	byte_length = 4
}