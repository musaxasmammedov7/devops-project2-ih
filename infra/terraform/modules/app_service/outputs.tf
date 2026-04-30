# Экспортируем внутренний домен (hostname) frontend-приложения, 
# который генерируется Azure (например, app-name.azurewebsites.net).
# Он понадобится Application Gateway для перенаправления трафика.
output "fe_app_default_hostname" {
  value = azurerm_linux_web_app.frontend.default_hostname
}

# Экспортируем внутренний домен backend-приложения.
output "be_app_default_hostname" {
  value = azurerm_linux_web_app.backend.default_hostname
}

# Экспортируем имя ресурса frontend-приложения, 
# нужно для связи с другими модулями (например, для настройки мониторинга).
output "fe_app_name" {
  value = azurerm_linux_web_app.frontend.name
}

# Экспортируем имя ресурса backend-приложения.
output "be_app_name" {
  value = azurerm_linux_web_app.backend.name
}
