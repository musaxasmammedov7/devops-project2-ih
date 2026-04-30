# Экспортируем публичный IP-адрес виртуальной машины SonarQube
output "sonar_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

# Экспортируем ID виртуальной машины
output "sonar_vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}
