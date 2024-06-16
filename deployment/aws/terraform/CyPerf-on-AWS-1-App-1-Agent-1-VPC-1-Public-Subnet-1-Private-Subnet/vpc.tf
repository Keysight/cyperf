module "Vpc" {
	source = "armdupre/module-1-vpc-1-public-subnet-1-private-subnet/aws"
	version = "2.6.0"
	InboundIPv4CidrBlocks = local.InboundIPv4CidrBlocks
	PrivateSubnetAvailabilityZone = local.PrivateSubnetAvailabilityZone
	PublicSubnetAvailabilityZone = local.PublicSubnetAvailabilityZone
	Region = local.Region
	Tag = local.AppTag
	UserEmailTag = local.UserEmailTag
	UserLoginTag = local.UserLoginTag
	UserProjectTag = local.UserProjectTag
}

resource "aws_security_group_rule" "PublicIngress30422" {
	type = "ingress"
	security_group_id = module.Vpc.PublicSecurityGroup.id
	protocol = "tcp"
	from_port = 30422
	to_port = 30422
	cidr_blocks = local.InboundIPv4CidrBlocks
}