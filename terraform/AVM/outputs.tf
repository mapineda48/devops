output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_nsg" {
  value = azurerm_network_security_group.vm_nsg.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm_vm.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm_vm.public_ip_address
}