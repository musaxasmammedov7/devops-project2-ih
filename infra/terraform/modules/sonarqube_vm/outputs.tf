output "sonar_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "sonar_vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}
