module "App" {
	source = "git::https://github.com/armdupre/terraform-google-module-cyperf-app.git?ref=5.0.0"
	Eth0SubnetName = local.PublicSubnetName
	Eth0VpcNetworkName = local.PublicVpcNetworkName
	MachineType = local.AppMachineType
	RegionName = data.google_client_config.current.region
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	ZoneName = data.google_client_config.current.zone
}

module "Agent1" {
	source = "git::https://github.com/armdupre/terraform-google-module-cyperf-agent.git?ref=5.0.0"
	AppEth0IpAddress = module.App.Instance.network_ip
	Eth0SubnetName = local.PublicSubnetName
	Eth0VpcNetworkName = local.PublicVpcNetworkName
	Eth1SubnetName = local.PrivateSubnetName
	Eth1VpcNetworkName = local.PrivateVpcNetworkName
	InstanceId = local.Agent1InstanceId
	MachineType = local.AgentMachineType
	RegionName = data.google_client_config.current.region
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	ZoneName = data.google_client_config.current.zone
	depends_on = [
		module.App
	]
}

module "Agent2" {
	source = "git::https://github.com/armdupre/terraform-google-module-cyperf-agent.git?ref=5.0.0"
	AppEth0IpAddress = module.App.Instance.network_ip
	Eth0PrivateIpAddress = local.Agent2Eth0PrivateIpAddress
	Eth0SubnetName = local.PublicSubnetName
	Eth0VpcNetworkName = local.PublicVpcNetworkName
	Eth1PrivateIpAddress = local.Agent2Eth1PrivateIpAddress
	Eth1PrivateIpAliases = local.Agent2Eth1PrivateIpAliases
	Eth1SubnetName = local.PrivateSubnetName
	Eth1VpcNetworkName = local.PrivateVpcNetworkName
	InstanceId = local.Agent2InstanceId
	MachineType = local.AgentMachineType
	RegionName = data.google_client_config.current.region
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	ZoneName = data.google_client_config.current.zone
	depends_on = [
		module.App
	]
}

resource "random_id" "RandomId" {
	byte_length = 4
}