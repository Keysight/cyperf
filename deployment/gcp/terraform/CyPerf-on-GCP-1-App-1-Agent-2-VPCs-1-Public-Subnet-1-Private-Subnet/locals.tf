locals {
	AgentMachineType = var.AgentMachineType
	Agent1InstanceId = "agent1"
	AppMachineType = var.AppMachineType
	AppTag = "cyperf"
	PublicFirewallRuleSourceIpRanges = var.PublicFirewallRuleSourceIpRanges == null ? [ "${data.http.ip.response_body}/32" ] : var.PublicFirewallRuleSourceIpRanges
	UserEmailTag = var.UserEmailTag == null ? data.google_client_openid_userinfo.current.email : var.UserEmailTag
	UserLoginTag = var.UserLoginTag == null ? "terraform" : var.UserLoginTag
	UserProjectTag = var.UserProjectTag == null ? lower(random_id.RandomId.id) : var.UserProjectTag
}