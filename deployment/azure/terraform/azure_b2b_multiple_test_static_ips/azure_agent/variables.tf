
variable "azure_agent_name" {
  type    = string
  description = "Azure deployment name"
}

variable "azure_owner" {
  type    = string
  description = "Azure owner name"
}

variable "resource_group" {
  type    = object({
    name = string,
    location = string
  })
  description = "Azure resource group where you want to deploy in"
}

variable "mgmt_subnet" {
  type = string
  description = "Management subnet id"
}

variable "test_subnet" {
  type = string
  description = "Test subnet id"
}

variable "controller_ip" {
  type = string
  description = "Controller or Controller-Proxy management IP"
}

variable "username" {
  type        = string
  default     = "admin"
  description = "Controller/Broker's authentication username"
  }
  
variable "password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Controller/Broker's authentication password"
}

variable "agent_version" {
  type        = string
  description = "Image id for the agent machines"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
  description = "Azure machine type"
}

variable "test_ip_start"{
  type = string
  description = "List of ip's that will be assigned on the test nic"
}

variable "public_key" {
  type = string
  description = "Path to the public key. This will be uesd to authenticate into the vm"
}

variable "agent_role" { 
  type = string
  description = "Agent role"
}