module "Vpc" {
	source = "armdupre/module-1-vpc-1-public-subnet-2-private-subnets/aws"
	InboundIPv4CidrBlock = local.InboundIPv4CidrBlock
	Private1SubnetAvailabilityZone = local.Private1SubnetAvailabilityZone
	Private2SubnetAvailabilityZone = local.Private2SubnetAvailabilityZone
	PublicSubnetAvailabilityZone = local.PublicSubnetAvailabilityZone
	Region = local.Region
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
	Version = local.AppVersion
}

resource "aws_security_group_rule" "PublicIngress30422" {
	type = "ingress"
	security_group_id = module.Vpc.PublicSecurityGroup.id
	protocol = "tcp"
	from_port = 30422
	to_port = 30422
	cidr_blocks = [ local.InboundIPv4CidrBlock ]
}