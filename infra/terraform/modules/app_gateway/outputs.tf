# Экспортируем ID балансировщика (необходимо для настройки мониторинга)
output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "backend_address_pool_fe_id" {
  value = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
}

output "backend_address_pool_be_id" {
  value = tolist(azurerm_application_gateway.appgw.backend_address_pool)[1].id
}
