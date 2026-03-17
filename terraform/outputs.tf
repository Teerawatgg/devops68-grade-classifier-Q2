output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Linux VM name"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "public_ip" {
  description = "Public IP address"
  value       = azurerm_public_ip.pip.ip_address
}

output "app_url" {
  description = "Application URL"
  value       = "http://${azurerm_public_ip.pip.ip_address}:${var.app_port}"
}

output "classify_example_url" {
  description = "Example endpoint for testing"
  value       = "http://${azurerm_public_ip.pip.ip_address}:${var.app_port}/classify?score=85"
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.pip.ip_address}"
}