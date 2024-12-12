module "Vpc" {
	source = "git::https://github.com/armdupre/terraform-google-module-3-vpcs-1-public-subnet-2-private-subnets.git?ref=5.0.0"
	PublicFirewallRuleSourceIpRanges = local.PublicFirewallRuleSourceIpRanges
	RegionName = data.google_client_config.current.region
	Tag = local.AppTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
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