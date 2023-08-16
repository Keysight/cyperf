module "App" {
	source = "armdupre/module-cyperf-app/aws"
	version = "0.2.5"
	Eth0SecurityGroupId = local.PublicSecurityGroupId
	Eth0SubnetId = local.PublicSubnetId
	InstanceType = local.AppInstanceType
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
}

module "Agent1" {
	source = "armdupre/module-cyperf-agent/aws"
	version = "0.2.5"
	AppEth0IpAddress = module.App.Instance.private_ip
	Eth0SecurityGroupId = local.PublicSecurityGroupId
	Eth0SubnetId = local.PublicSubnetId
	Eth1SecurityGroupId = local.PrivateSecurityGroupId
	Eth1SubnetId = local.PrivateSubnetId
	InstanceId = local.Agent1InstanceId
	InstanceType = local.AgentInstanceType
	PlacementGroupId = aws_placement_group.PlacementGroup.id
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	depends_on = [
		aws_placement_group.PlacementGroup,
		module.App
	]
}

module "Agent2" {
	source = "armdupre/module-cyperf-agent/aws"
	version = "0.2.5"
	AppEth0IpAddress = module.App.Instance.private_ip
	Eth0PrivateIpAddress = local.Agent2Eth0PrivateIpAddress
	Eth0SecurityGroupId = local.PublicSecurityGroupId
	Eth0SubnetId = local.PublicSubnetId
	Eth1PrivateIpAddresses = local.Agent2Eth1PrivateIpAddresses
	Eth1SecurityGroupId = local.PrivateSecurityGroupId
	Eth1SubnetId = local.PrivateSubnetId
	InstanceId = local.Agent2InstanceId
	InstanceType = local.AgentInstanceType
	PlacementGroupId = aws_placement_group.PlacementGroup.id
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	depends_on = [
		aws_placement_group.PlacementGroup,
		module.App
	]
}

resource "aws_placement_group" "PlacementGroup" {
	name = local.PlacementGroupName
	strategy = local.PlacementGroupStrategy
}