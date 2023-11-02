module "Vpc" {
	source = "armdupre/module-3-vpcs-1-public-subnet-2-private-subnets/google"
	PublicFirewallRuleSourceIpRanges = local.PublicFirewallRuleSourceIpRanges
	RegionName = data.google_client_config.current.region
	Tag = local.AppTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	Version = local.AppVersion
}

resource "google_compute_network_peering" "Private1VpcNetworkPeer" {
	name = local.Private1VpcNetworkPeerName
	network = module.Vpc.Private1VpcNetwork.id
	peer_network = module.Vpc.Private2VpcNetwork.id
}

resource "google_compute_network_peering" "Private2VpcNetworkPeer" {
	name = local.Private2VpcNetworkPeerName
	network = module.Vpc.Private2VpcNetwork.id
	peer_network = module.Vpc.Private1VpcNetwork.id
}