module "Vnet1" {
	source = "armdupre/module-1-vnet-1-public-subnet-1-private-subnet/azurerm"
	InstanceId = local.Vnet1InstanceId
	PublicSecurityRuleSourceIpPrefix = local.PublicSecurityRuleSourceIpPrefix
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	Version = local.AppVersion
}

module "Vnet2" {
	source = "armdupre/module-1-vnet-1-public-subnet-1-private-subnet/azurerm"
	InstanceId = local.Vnet2InstanceId
	PrivateSubnetPrefix = local.Vnet2PrivateSubnetPrefix
	PublicSecurityRuleSourceIpPrefix = local.PublicSecurityRuleSourceIpPrefix
	PublicSubnetPrefix = local.Vnet2PublicSubnetPrefix
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	Version = local.AppVersion
	VnetAddressPrefix = local.Vnet2AddressPrefix
}

resource "azurerm_virtual_network_peering" "Vnet1Peering" {
	name = local.Vnet1PeeringName
	resource_group_name = azurerm_resource_group.ResourceGroup.name
	virtual_network_name = module.Vnet1.Vnet.name
	remote_virtual_network_id = module.Vnet2.Vnet.id
}

resource "azurerm_virtual_network_peering" "Vnet2Peering" {
	name = local.Vnet2PeeringName
	resource_group_name = azurerm_resource_group.ResourceGroup.name
	virtual_network_name = module.Vnet2.Vnet.name
	remote_virtual_network_id = module.Vnet1.Vnet.id
}