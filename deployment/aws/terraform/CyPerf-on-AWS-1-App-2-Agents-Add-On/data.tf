data "aws_region" "current" {}

data "aws_availability_zones" "available" {
	state = "available"
}

data "aws_security_group" "PrivateSecurityGroup" {
	filter {
		name = "tag:Name"
		values = [ local.PrivateSecurityGroupName ]
    }
}

data "aws_subnet" "PrivateSubnet" {
	filter {
		name = "tag:Name"
		values = [ local.PrivateSubnetName ]
    }
}

data "aws_security_group" "PublicSecurityGroup" {
	filter {
		name = "tag:Name"
		values = [ local.PublicSecurityGroupName ]
    }
}

data "aws_subnet" "PublicSubnet" {
	filter {
		name = "tag:Name"
		values = [ local.PublicSubnetName ]
    }
}