locals {
	AgentUserName = "ubuntu"
	AgentVmSize = var.AgentVmSize
	Agent1InstanceId = "agent1"
	Agent1Eth1IpAddresses = [ "10.0.2.12", "10.0.2.13", "10.0.2.14" ]
	Agent2Eth0IpAddress = "10.0.10.12"
	Agent2Eth1IpAddresses = [ "10.0.2.22", "10.0.2.23", "10.0.2.24" ]
	Agent2InstanceId = "agent2"
	AppTag = "cyperf"
	AzureMetadataServerUrl = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
	Preamble = "${local.UserLoginTag}-${local.AppTag}"
	PublicSecurityRuleSourceIpPrefixes = var.PublicSecurityRuleSourceIpPrefixes
	ResourceGroupLocation = var.ResourceGroupLocation
	ResourceGroupName = var.ResourceGroupName
	SshKeyAlgorithm = "RSA"
	SshKeyName = "${local.Preamble}-ssh-key"
	SshKeyRsaBits = "4096"
	SubscriptionId = var.SubscriptionId
	UserEmailTag = var.UserEmailTag
	UserLoginTag = var.UserLoginTag
	UserProjectTag = var.UserProjectTag
}