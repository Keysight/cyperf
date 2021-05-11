variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zone" {
  type    = string
  default = "us-east-2a"
}

variable "aws_access_key" {
  type = string
  default = "AKIAQAUTNXTKAWYWM353"
}

variable "aws_secret_key" {
  type = string
  default = "VbUswOTgTWUlWvJOvd1l3uKECfn5YeXZlHxQAwPF"
}

variable "aws_stack_name" {
  type = string
  default = "b2b"
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  default = "id_rsa_ghost"
  description = "The key used to ssh into VMs"
}

variable "aws_mdw_machine_type"{
  type = string
  default = "t2.xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c4.2xlarge"
  description = "Agent machines instance type"
}

variable "mdw_version" {
  type        = string
  default     = "1-0-310-releasecyperfapr2021"
  description = "Image id for the MDW machine"
}

variable "agent_version" {
  type        = string
  default     = "1-0-181-master-tiger-1-0-0-936"
  description = "Image id for the agent machines"
}