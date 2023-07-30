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