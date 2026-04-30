output "fe_app_default_hostname" {
  value = azurerm_linux_web_app.frontend.default_hostname
}

output "be_app_default_hostname" {
  value = azurerm_linux_web_app.backend.default_hostname
}

output "fe_app_name" {
  value = azurerm_linux_web_app.frontend.name
}

output "be_app_name" {
  value = azurerm_linux_web_app.backend.name
}
