resource "azurerm_ssh_public_key" "SshKey" {
	name = local.SshKeyName
	resource_group_name = local.ResourceGroupName
	location = local.ResourceGroupLocation
	public_key = tls_private_key.SshKey.public_key_openssh
}

resource "tls_private_key" "SshKey" {
	algorithm = local.SshKeyAlgorithm
	rsa_bits = local.SshKeyRsaBits
}