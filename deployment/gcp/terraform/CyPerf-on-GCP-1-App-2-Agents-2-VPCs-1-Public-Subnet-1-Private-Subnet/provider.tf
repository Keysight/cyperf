provider "google" {
	credentials = var.Credentials
	project = var.ProjectId
	region = var.RegionName
	zone = var.ZoneName
}