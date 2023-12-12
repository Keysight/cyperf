variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "availability_zone" {
  type    = string
  default = "us-west-2a"
}

variable "aws_access_key" {
  type = string
  default = "xxxxxxxxxxxx"
  description = "AWS-cli access key"
}

variable "aws_secret_key" {
  type = string
  default = "xxxxxxxxxxx"
  description = "AWS-cli secret key"
}

variable "aws_stack_name" {
  type = string
  default = "cyperftestexist"
  description = "Stack name, prefix for all resources"
}

variable "aws_owner" {
  type = string
  default = "default"
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  default = "secret key"
  description = "The key used to ssh into VMs"
}

variable "aws_mdw_machine_type"{
  type = string
  default = "c5.2xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c5.2xlarge"
  description = "Agent machines instance type"
}

variable "agents" {
  type = number
  default = 2
  description = "Number of clients to be deployed"
}

variable "aws_controller_ip" {
  type  = string
  default = "172.16.6.2"
  description = "Pre exists controller or controller proxy ip"
}

variable "mgmt_test_subnet_name" {
  type        = string
  default = "existing-vpc-management-subnet"
  description = "The name of the mgmt and test subnet that the VMs will attach to"
}

variable "agents_sg_name" {
  type        = string
  default = "existing-vpc-agent-security-group"
  description = "Agents security group name"
}