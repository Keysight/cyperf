variable "GCP_PROJECT_NAME" {
  type    = string
  default = "<specify your project name>"
}

variable "GCP_REGION_NAME" {
  type    = string
  default = "us-east1"
}

variable "GCP_ZONE_NAME" {
  type    = string
  default = "us-east1-b"
}

variable "GCP_OWNER_TAG" {
  type    = string
  default = "<specify the gcp owner tag name>"
}

variable "GCP_PROJECT_TAG" {
  type    = string
  default = "keysight-gcp-cyperf"
}

variable "GCP_SSH_KEY" {
  type = string
  default = "<specify the gcp public ssh key file path>"
}
variable "GCP_CREDENTIALS_FILE" {
  type = string
  default = "<create gcp credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys>"
}

variable "GCP_MDW_MACHINE_TYPE" {
  type    = string
  default = "n1-standard-4"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-0"
  description = "Image id for the cyperf controller machine"
}

