data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
	state = "available"
}

data "http" "ip" {
	url = "https://ifconfig.me"
}