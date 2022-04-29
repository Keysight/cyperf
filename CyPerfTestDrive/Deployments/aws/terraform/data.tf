data "aws_region" "current" {}

data "aws_availability_zones" "available" {
	state = "available"
}

data "aws_ami" "AMI_APP" {
	owners = [ local.ControllerAmiOwner ]
	filter {
		name = "name"
		values = [ local.ControllerAmiName ]
    }
}

data "aws_ami" "AMI_AGENT" {
	owners = [ local.AgentAmiOwner ]
	filter {
		name = "name"
		values = [ local.AgentAmiName ]
    }
}