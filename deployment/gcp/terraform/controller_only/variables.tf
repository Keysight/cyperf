variable "gcp_project_name" {
  type    = string
  description ="Project name"
}

variable "gcp_owner_tag" {
  type    = string
  description = "GCP owner tag name"
}

variable "gcp_ssh_key" {
  type = string
  description = "The gcp public ssh key file path"
}

variable "gcp_credential_file" {
  type = string
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

variable "gcp_allowed_cidr" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "gcp_mdw_machine_type" {
  type    = string
  default = "n1-standard-4"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-7"
  description = "Image id for the cyperf controller machine"
}

