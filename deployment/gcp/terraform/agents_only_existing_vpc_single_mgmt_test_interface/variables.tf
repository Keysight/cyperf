variable "gcp_project_name" {
  type    = string
  default = "kt-nas-cyperf-dev"
  description ="Project name"
}

variable "gcp_region_name" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone_name" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_credential_file" {
  type = string
  default = "<credential json file path>"
  description = "GCP credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys"
}

variable "gcp_deployment" {
  type    = string
  default = "cyperf-agents-ext-vpc"
  description = "GCP owner tag name"
}

variable "gcp_owner"{
  type    = string
  default = "//default"
  description = "GCP owner tag name"
}

variable "gcp_project_tag" {
  type    = string
  default = "gcp-cyperf"
}

variable "gcp_ssh_key" {
  type = string
  default = "<ssh public key path>"
  description = "The gcp public ssh key file path"
}

variable "gcp_allowed_cidr" {
  type = list(string)
  default = ["213.249.122.232/29", "121.244.60.104/29","193.226.172.40/29","198.223.187.0/29","198.233.187.0/29","0.0.0.0/0"]
}

variable "gcp_agent_machine_type" {
  type    = string
  default = "c2-standard-4"
}

variable "gcp_controller_ip" {
  type  = string
  default = "172.16.6.2"
}

variable "gcp_agent_mgmt_test_subnet" {
  type  = string
  default = "cyperf-management-test-subnet"
}

variable "gcp_agent_number" {
  type  = number
  default = 2
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-2-6"
  description = "Image id for the controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-2-6"
  description = "Image id for the agent machines"
}
