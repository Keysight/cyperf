output "name" {
    value = azurerm_linux_virtual_machine.azr_automation_agent.name
}
output "private_ip" {
    value = azurerm_linux_virtual_machine.azr_automation_agent.private_ip_address
}
output "public_ip" {
    value = azurerm_linux_virtual_machine.azr_automation_agent.public_ip_address
}