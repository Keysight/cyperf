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
}

variable "agents" {
  type = number
  default = 2
  description = "Number of agents to be deployed"
}

variable "controller_image" {
  default = "https://cyperf.blob.core.windows.net/keysight-cyperf-2-5/keysight-cyperf-controller-2-5.vhd"
  type = string
  description = "Controller image path"
}

variable "agent_image" {
  default = "https://cyperf.blob.core.windows.net/keysight-cyperf-2-5/keysight-cyperf-agent-2-5.vhd"
  type = string
  description = "Agent image path"
}

variable "mdw_name" {
  type        = string
  default     = "keysight-cyperf-controller-2-5"
  description = "Name for the cyperf controller machine"
}

variable "agent_name" {
  type        = string
  default     = "keysight-cyperf-agent-2-5"
  description = "Name for the cyperf agent machines"
}