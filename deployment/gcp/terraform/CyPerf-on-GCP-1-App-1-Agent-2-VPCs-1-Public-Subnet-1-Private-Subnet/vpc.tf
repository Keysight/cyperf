module "Vpc" {
	source = "armdupre/module-2-vpcs-1-public-subnet-1-private-subnet/google"
	PublicFirewallRuleSourceIpRanges = local.PublicFirewallRuleSourceIpRanges
	RegionName = data.google_client_config.current.region
	Tag = local.AppTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	Version = local.AppVersion
}