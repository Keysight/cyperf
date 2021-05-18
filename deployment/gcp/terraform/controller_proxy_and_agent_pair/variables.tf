variable "GCP_PROJECT_NAME" {
  type    = string
  description ="Project name"
}

variable "GCP_OWNER_TAG" {
  type    = string
  description = "GCP owner tag name"
}

variable "GCP_SSH_KEY" {
  type = string
  description = "The gcp public ssh key file path"
}

variable "GCP_CREDENTIALS_FILE" {
  type = string
  description = "GCP credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys"
}

variable "GCP_REGION_NAME" {
  type    = string
  default = "us-east1"
}

variable "GCP_ZONE_NAME" {
  type    = string
  default = "us-east1-b"
}

variable "GCP_PROJECT_TAG" {
  type    = string
  default = "keysight-gcp-cyperf"
}


variable "GCP_BROKER_MACHINE_TYPE" {
  type    = string
  default = "n1-standard-2"
}

variable "GCP_AGENT_MACHINE_TYPE" {
  type    = string
  default = "c2-standard-16"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0"
  description = "Image id for the cyperf agent machines"
}

variable "broker_image" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-1-0"
  description = "Image id for the cyperf controller proxy machines"
}