variable "resource_group" {
  type    = object({
    aws_agent_security_group = string,
    aws_ControllerManagementSubnet = string
    aws_AgentTestSubnet = string
    //instance_profile = string
  })
  description = "AWS resource group where you want to deploy in"
}

variable "tags" {
  type    = object({
    aws_owner = string,
    project_tag = string,
    options_tag = string
  })
  description = "AWS tags"
}

variable "aws_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  description = "The key used to ssh into VMs"
}

variable "aws_agent_machine_type" {
  type = string
  description = "Agent machines instance type"
}

variable "agent_role" { 
  type = string
  description = "Agent role: server or client"
}

variable "agent_init_cli" { 
  type = string
  description = "Init script"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-6-0"
  description = "Version for the cyperf agent"
}

variable "agent_product_code" {
  type        = string
  default     = "zskzjts7t5crpmiic5drkq0j"
  description = "Product code from the AWS Marketplace the cyperf agent"
}
