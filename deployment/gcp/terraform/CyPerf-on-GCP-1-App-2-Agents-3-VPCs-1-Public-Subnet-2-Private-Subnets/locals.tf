locals {
	AgentMachineType = var.AgentMachineType
	Agent1InstanceId = "agent1"
	Agent2Eth0PrivateIpAddress = "10.0.10.12"
	Agent2Eth0PublicIpAddressName = "${local.Preamble}-eth0-ip-addr"
	Agent2Eth1PrivateIpAddress = "10.0.3.15"
	Agent2Eth1PrivateIpAliases = "/28"
	Agent2InstanceId = "agent2"
	Agent2InstanceName = "${local.Preamble}-instance"
	AppMachineType = var.AppMachineType
	AppTag = "cyperf"
	AppVersion = "2-5"
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}-${local.AppVersion}-${local.Agent2InstanceId}"
	Private1VpcNetworkPeerName = "${local.Preamble}-test1-vpc-peer"
	Private2VpcNetworkPeerName = "${local.Preamble}-test2-vpc-peer"
	ProjectId = var.ProjectId
	PublicFirewallRuleSourceIpRanges = var.PublicFirewallRuleSourceIpRanges
	RegionName = var.RegionName
	UserEmailTag = var.UserEmailTag
	UserLoginTag = var.UserLoginTag
	UserProjectTag = var.UserProjectTag
	ZoneName = var.ZoneName
}