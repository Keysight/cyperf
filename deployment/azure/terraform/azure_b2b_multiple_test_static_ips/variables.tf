variable "azure_project_name" {
  type    = string
  description = "Project name"
}

variable "azure_owner_tag" {
  type    = string
  description = "Deployment name"
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

variable "azure_mdw_machine_type" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
  description = "Possible options: Standard_F4s_v2 / Standard_F16s_v2 / Standard_D48s_v4 / Standard_D48_v4"
}

variable "agents" {
  type = number
  default = 2
  description = "Number of agents to be deployed"
}

variable "cyperf_version" {
  type        = string
  default     = "0.5.0"
  description = "CyPerf release version"
}

variable "mdw_name" {
  type        = string
  default     = "keysight-cyperf-controller-5-0"
  description = "Name for the cyperf controller machine"
}

variable "agent_name" {
  type        = string
  default     = "keysight-cyperf-agent-5-0"
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