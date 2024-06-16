locals {
	AgentInstanceType = var.AgentInstanceType
	Agent1InstanceId = "agent1"
	AppInstanceType = var.AppInstanceType
	AppTag = "cyperf"
	InboundIPv4CidrBlocks = var.InboundIPv4CidrBlocks
	PlacementGroupName = "${local.Preamble}-placement-group-${local.Region}"
	PlacementGroupStrategy = "cluster"
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}"
	PrivateSubnetAvailabilityZone = var.PrivateSubnetAvailabilityZone
	PublicSubnetAvailabilityZone = var.PublicSubnetAvailabilityZone
	Region = data.aws_region.current.name
	UserEmailTag = var.UserEmailTag
	UserLoginTag = var.UserLoginTag
	UserProjectTag = var.UserProjectTag
}