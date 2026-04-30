# Экспортируем ID балансировщика (необходимо для настройки мониторинга)
output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}
