variable "GCP_OWNER_TAG" {
  type    = string
  default = "<specify the gcp owner tag name>"
}

variable "GCP_PROJECT_NAME" {
  type    = string
  default = "<specify your project name>"
}

variable "GCP_PROJECT_TAG" {
  type    = string
  default = "keysight-gcp-cyperf"
}

variable "GCP_CREDENTIALS" {
  type = string
  default = "<create gcp credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys>"
}

variable "GCP_REGION_NAME" {
  type    = string
  default = "<specify your gcp region name for deployment>"
}

variable "GCP_ZONE_NAME" {
  type    = string
  default = "<specify your gcp zone name for deployment>"
}