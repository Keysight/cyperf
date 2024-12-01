module "Vnet" {
	source = "git::https://github.com/armdupre/terraform-azurerm-module-1-vnet-1-public-subnet-2-private-subnets.git?ref=5.0.0"
	PublicSecurityRuleSourceIpPrefixes = local.PublicSecurityRuleSourceIpPrefixes
	ResourceGroupLocation = azurerm_resource_group.ResourceGroup.location
	ResourceGroupName = azurerm_resource_group.ResourceGroup.name
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
}