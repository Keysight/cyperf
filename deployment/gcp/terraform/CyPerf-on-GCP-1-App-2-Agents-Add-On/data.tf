data "google_client_config" "current" {}

data "google_client_openid_userinfo" "current" {}

data "google_compute_subnetwork" "PrivateSubnet" {
	name = local.PrivateSubnetName
}

data "google_compute_network" "PrivateVpcNetwork" {
	name = local.PrivateVpcNetworkName
}

data "google_compute_subnetwork" "PublicSubnet" {
	name = local.PublicSubnetName
}

data "google_compute_network" "PublicVpcNetwork" {
	name = local.PublicVpcNetworkName
}

data "http" "ip" {
	url = "https://ifconfig.me"
}