variable "azure_project_name" {
  type    = string
  description = "Project name"
}

variable "azure_owner_tag" {
  type    = string
  description = "Owner tag name"
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

variable "public_key" {
  type = string
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

variable "azure_allowed_cidr" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of allowed IP ranges on the machines"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
}

variable "cyperf_version" {
  type        = string
  default     = "0.3.0"
  description = "CyPerf release version"
}

variable "broker_version" {
  type        = string
  default     = "0.3.0"
  description = "CyPerf release version"
}

variable "agent_name" {
  type        = string
  default     = "keysight-cyperf-agent-3-0"
  description = "Name for the cyperf agent machines"
}

variable "broker_name" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-3-0"
  description = "Name for the cyperf broker machines"
}

variable "azure_broker_machine_type" {
  type        = string
  default     = "Standard_F2s_v2"
  description = "controller-proxy image"
}

variable "broker_username" {
  type        = string
  default     = "admin"
  description = "Broker's authentication username"
  }
  
variable "broker_password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Broker's authentication password"
}