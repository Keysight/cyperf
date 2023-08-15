locals {
	AgentInstanceType = var.AgentInstanceType
	Agent1InstanceId = "agent1"
	Agent2Eth0PrivateIpAddress = "10.0.10.12"
	Agent2Eth1PrivateIpAddresses = [ "10.0.2.22" ]
	Agent2InstanceId = "agent2"
	AppInstanceType = var.AppInstanceType
	AppTag = "cyperf"
	AppVersion = "2-5"
	PlacementGroupName = "${local.Preamble}-placement-group-${local.Region}"
	PlacementGroupStrategy = "cluster"
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}-${local.AppVersion}"
	PrivateSecurityGroupId = var.PrivateSecurityGroupId
	PrivateSubnetId = var.PrivateSubnetId
	PublicSecurityGroupId = var.PublicSecurityGroupId
	PublicSubnetId = var.PublicSubnetId
	Region = data.aws_region.current.name
	UserEmailTag = var.UserEmailTag
	UserLoginTag = var.UserLoginTag
	UserProjectTag = var.UserProjectTag
}