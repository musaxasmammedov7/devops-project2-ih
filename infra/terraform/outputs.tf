output "application_url" {
  description = "The public URL to access the application via App Gateway"
  value       = var.custom_domain_name != "" && var.appgw_ssl_certificate_key_vault_secret_id != "" ? "https://${var.custom_domain_name}" : "http://${azurerm_public_ip.appgw_pip.ip_address}"
}

output "app_gateway_public_ip" {
  description = "The public IP address of Application Gateway"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "appgw_key_vault_name" {
  description = "The Key Vault name used for the Application Gateway TLS certificate"
  value       = azurerm_key_vault.appgw.name
}

output "sonarqube_url" {
  description = "The public URL to access SonarQube"
  value       = "http://${module.sonarqube_vm.sonar_public_ip}:9000"
}

output "sonar_public_ip_raw" {
  description = "Raw Public IP for Ansible inventory"
  value       = module.sonarqube_vm.sonar_public_ip
}

output "sonar_ssh_command" {
  description = "SSH command to connect to SonarQube VM"
  value       = "ssh ${var.vm_admin_username}@${module.sonarqube_vm.sonar_public_ip}" # Собираем команду: ssh имя_пользователя@IP_адрес
}

# Экспортируем ключ (Instrumentation Key) от Application Insights (мониторинг)
output "app_insights_instrumentation_key" {
  value     = module.monitoring.instrumentation_key # Берем ключ из модуля monitoring
  sensitive = true                                  # Помечаем как конфиденциальные данные, чтобы Terraform не выводил их в открытом виде в консоль
}
