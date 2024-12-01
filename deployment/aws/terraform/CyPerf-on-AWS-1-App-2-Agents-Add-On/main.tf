module "App" {
	source = "git::https://github.com/armdupre/terraform-aws-module-cyperf-app.git?ref=5.0.0"
	Eth0SecurityGroupId = data.aws_security_group.PublicSecurityGroup.id
	Eth0SubnetId = data.aws_subnet.PublicSubnet.id
	InstanceType = local.AppInstanceType
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
}

module "Agent1" {
	source = "git::https://github.com/armdupre/terraform-aws-module-cyperf-agent.git?ref=5.0.0"
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
	source = "git::https://github.com/armdupre/terraform-aws-module-cyperf-agent.git?ref=5.0.0"
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

resource "random_id" "RandomId" {
	byte_length = 4
}