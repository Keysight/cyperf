module "App" {
	source = "armdupre/module-cyperf-app/aws"
	version = "2.6.0"
	Eth0SecurityGroupId = data.aws_security_group.PublicSecurityGroup.id
	Eth0SubnetId = data.aws_subnet.PublicSubnet.id
	InstanceType = local.AppInstanceType
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
}

module "Agent1" {
	source = "armdupre/module-cyperf-agent/aws"
	version = "2.6.1"
	AppEth0IpAddress = module.App.Instance.private_ip
	Eth0SecurityGroupId = data.aws_security_group.PublicSecurityGroup.id
	Eth0SubnetId = data.aws_subnet.PublicSubnet.id
	Eth1SecurityGroupId = data.aws_security_group.PrivateSecurityGroup.id
	Eth1SubnetId = data.aws_subnet.PrivateSubnet.id
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
	version = "2.6.1"
	AppEth0IpAddress = module.App.Instance.private_ip
	Eth0PrivateIpAddress = local.Agent2Eth0PrivateIpAddress
	Eth0SecurityGroupId = data.aws_security_group.PublicSecurityGroup.id
	Eth0SubnetId = data.aws_subnet.PublicSubnet.id
	Eth1PrivateIpAddresses = local.Agent2Eth1PrivateIpAddresses
	Eth1SecurityGroupId = data.aws_security_group.PrivateSecurityGroup.id
	Eth1SubnetId = data.aws_subnet.PrivateSubnet.id
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