variable "azure_project_name" {
  type        = string
  description = "Project name"
}

variable "azure_owner_tag" {
  type        = string
  description = "Owner tag name"
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

variable "public_key" {
  type        = string
  description = "Path to the public key used to ssh into machine"
}

variable "azure_region_name" {
  type    = string
  default = "centralus"
}

variable "azure_admin_username" {
  type    = string
  default = "cyperf"
}

variable "azure_project_tag" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "azure_allowed_cidr_ipv4" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of allowed IPv4 ranges on the machines"
}
variable "azure_allowed_cidr_ipv6" {
  type    = list(string)
  default = ["::/0"]
}
variable "stack_type" {
  type        = string
  default     = "ipv4"
  description = "Possible options: ipv4 / ipv6 / dual-stack"
}

variable "azure_mdw_machine_type" {
  type    = string
  default = "Standard_F16s_v2"
  description = "Possible options: Standard_F4s_v2 / Standard_F16s_v2 / Standard_D48s_v4 / Standard_D48_v4"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F16s_v2"
}

variable "controller_image" {
  default     = "https://cyperf.blob.core.windows.net/keysight-cyperf-6-0/keysight-cyperf-controller-6-0.vhd"
  type        = string
  description = "Controller image path"
}

variable "agent_image" {
  default     = "https://cyperf.blob.core.windows.net/keysight-cyperf-6-0/keysight-cyperf-agent-6-0.vhd"
  type        = string
  description = "Agent image path"
}

variable "mdw_name" {
  type        = string
  default     = "keysight-cyperf-controller-6-0"
  description = "Name for the cyperf controller machine"
}

variable "agent_name" {
  type        = string
  default     = "keysight-cyperf-agent-6-0"
  description = "Name for the cyperf agent machines"
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
variable "accelerated_connections" {
  type        = string
  default     = "disable"
  description = "enable / disable accelerated connections for test interface on the deployed setup. Enabling this option will enhance performance."
}
variable "server_IP_stack_range" {
  type        = string
  default     = "20.0.0.0/16"
  description = "IP Stack CIDR range for the Server agent used while running ER tests"
}
variable "client_IP_stack_range" {
  type        = string
  default     = "30.0.0.0/16"
  description = "IP Stack CIDR range for the Client agent used while running ER tests"
}