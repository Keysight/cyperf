module "App" {
	source = "armdupre/module-cyperf-app/google"
	version = "0.2.5"
	Eth0SubnetName = module.Vpc.PublicSubnet.name
	Eth0VpcNetworkName = module.Vpc.PublicVpcNetwork.name
	MachineType = local.AppMachineType
	RegionName = data.google_client_config.current.region
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	ZoneName = data.google_client_config.current.zone
	depends_on = [
		module.Vpc.PublicSubnet,
		module.Vpc.PublicVpcNetwork
	]
}

module "Agent1" {
	source = "armdupre/module-cyperf-agent/google"
	version = "0.2.5"
	AppEth0IpAddress = module.App.Instance.network_ip
	Eth0SubnetName = module.Vpc.PublicSubnet.name
	Eth0VpcNetworkName = module.Vpc.PublicVpcNetwork.name
	Eth1SubnetName = module.Vpc.PrivateSubnet.name
	Eth1VpcNetworkName = module.Vpc.PrivateVpcNetwork.name
	InstanceId = local.Agent1InstanceId
	MachineType = local.AgentMachineType
	RegionName = data.google_client_config.current.region
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	ZoneName = data.google_client_config.current.zone
	depends_on = [
		module.App,
		module.Vpc.PublicSubnet,
		module.Vpc.PublicVpcNetwork
	]
}