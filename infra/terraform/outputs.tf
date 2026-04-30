output "application_url" {
  description = "The public URL to access the application via App Gateway"
  value       = "http://${azurerm_public_ip.appgw_pip.ip_address}"
}

output "sonarqube_url" {
  description = "The public URL to access SonarQube"
  value       = "http://${module.sonarqube_vm.sonar_public_ip}:9000"
}

output "sonar_ssh_command" {
  description = "SSH command to connect to SonarQube VM"
  value       = "ssh ${var.vm_admin_username}@${module.sonarqube_vm.sonar_public_ip}"
}

output "app_insights_instrumentation_key" {
  value     = module.monitoring.instrumentation_key
  sensitive = true
}
