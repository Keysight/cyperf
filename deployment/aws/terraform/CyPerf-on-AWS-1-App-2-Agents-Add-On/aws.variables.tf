variable "AwsAccessCredentialsAccessKey" {
	default = null
	description = "Access key component of credentials used for programmatic calls to AWS."
	sensitive = true
	type = string
}

variable "AwsAccessCredentialsSecretKey" {
	default = null
	description = "Secret access key component of credentials used for programmatic calls to AWS."
	sensitive = true
	type = string
}