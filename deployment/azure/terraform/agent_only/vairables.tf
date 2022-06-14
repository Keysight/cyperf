variable "azure_agent_name" {
  type    = string
  description = "Azure deployment name"
}

variable "subscription_id" {
  type = string
  description = "Subscription id"
}

variable "client_id" {
  type = string
  description = "Client id"
}

variable "client_secret" {
  type = string
  description = "Client secret key"
}

variable "tenant_id" {
  type = string
  description = "Tenant id"
}

variable "resource_group_name" {
  type = string
  description = "Resource group name"
}

variable "resource_group_location" {
  type = string
  description = "Resource group location"
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

variable "public_key" {
  type = string
  description = "Path to the public key. This will be uesd to authenticate into the vm"
}

variable "agent_image" {
  default = "https://cyperf.blob.core.windows.net/keysight-cyperf-1-6/keysight-cyperf-agent-1-6.vhd"
  type = string
  description = "Agent image path"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-6"
  description = "Image id for the agent machines"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
  description = "Azure machine type"
}

variable "agent_role" {
  type = string
  default = "azure-agent"
  description = "Agent role. This will act as a tag in UI"
}