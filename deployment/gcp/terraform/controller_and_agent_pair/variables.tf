variable "gcp_project_name" {
  type        = string
  description = "Project name"
}

variable "gcp_owner_tag" {
  type        = string
  description = "GCP owner tag name"
}

variable "gcp_ssh_key" {
  type        = string
  description = "The gcp public ssh key file path"
}

variable "gcp_credential_file" {
  type        = string
  description = "GCP credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys"
}

variable "gcp_region_name" {
  type    = string
  default = "us-east1"
}

variable "gcp_zone_name" {
  type    = string
  default = "us-east1-b"
}

variable "gcp_project_tag" {
  type    = string
  default = "keysight-gcp-cyperf"
}

variable "gcp_allowed_cidr_ipv4" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "gcp_allowed_cidr_ipv6" {
  type    = list(string)
  default = ["::/0"]
}
variable "stack_type" {
  type        = string
  default     = "ipv4"
  description = "Possible options: ipv4 / dual-stack"
}

variable "gcp_mdw_machine_type" {
  type    = string
  default = "c2-standard-8"
}

variable "gcp_agent_machine_type" {
  type    = string
  default = "c2-standard-4"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-6-0"
  description = "Image id for the cyperf controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-6-0"
  description = "Image id for the cyperf agent machines"
}