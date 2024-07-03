variable "azure_agent_name" {
  type        = string
  description = "Azure deployment name"
}

variable "subscription_id" {
  type        = string
  description = "Subscription id"
}

variable "client_id" {
  type        = string
  description = "Client id"
}

variable "client_secret" {
  type        = string
  description = "Client secret key"
}

variable "tenant_id" {
  type        = string
  description = "Tenant id"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "Resource group location"
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual network name"
}

variable "mgmt_subnet" {
  type        = string
  description = "Management subnet name"
}

variable "test_subnet" {
  type        = string
  description = "Test subnet name"
}

variable "controller_ip" {
  type        = string
  description = "Controller or Controller-Proxy management IP"
}

variable "controller_username" {
  type        = string
  default     = "admin"
  description = "Controller's authentication username"
}

variable "controller_password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Controller's authentication password"
}
variable "public_key" {
  type        = string
  description = "Path to the public key. This will be uesd to authenticate into the vm"
}

variable "agent_image" {
  default     = "https://cyperf.blob.core.windows.net/keysight-cyperf-3-0/keysight-cyperf-agent-3-0.vhd"
  type        = string
  description = "Agent image path"
}

variable "azure_agent_machine_type" {
  type        = string
  default     = "Standard_F4s_v2"
  description = "Azure machine type"
}

variable "agent_role" {
  type        = string
  default     = "azure-agent"
  description = "Agent role. This will act as a tag in UI"
}
variable "stack_type" {
  type        = string
  default     = "ipv4"
  description = "Possible options: ipv4 / ipv6 / dual-stack"
}
variable "accelerated_connections" {
  type        = string
  default     = "disable"
  description = "enable / disable accelerated connections for test interface on the deployed setup. Enabling this option will enhance performance."
}