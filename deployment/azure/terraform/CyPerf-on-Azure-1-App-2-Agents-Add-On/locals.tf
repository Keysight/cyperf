locals {
	AgentVmSize = var.AgentVmSize
	Agent1InstanceId = "agent1"
	Agent2Eth0IpAddress = "10.0.10.12"
	Agent2Eth1IpAddresses = ["10.0.2.22"]
	Agent2InstanceId = "agent2"
	AppTag = "cyperf"
	AppVmSize = var.AppVmSize
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}"
	PrivateSubnetName = var.PrivateSubnetName
	PublicSubnetName = var.PublicSubnetName
	ResourceGroupLocation = var.ResourceGroupLocation
	ResourceGroupName = var.ResourceGroupName
	SshKeyAlgorithm = "RSA"
	SshKeyName = "${local.Preamble}-ssh-key"
	SshKeyRsaBits = "4096"
	SubscriptionId = var.SubscriptionId
	UserEmailTag = var.UserEmailTag == null ? data.azurerm_client_config.current.client_id : var.UserEmailTag
	UserLoginTag = var.UserLoginTag == null ? "terraform" : var.UserLoginTag
	UserProjectTag = var.UserProjectTag == null ? random_id.RandomId.id : var.UserProjectTag
	VnetName = var.VnetName
}