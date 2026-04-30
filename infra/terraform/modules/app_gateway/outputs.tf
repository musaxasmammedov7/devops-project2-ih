# Экспортируем ID балансировщика (необходимо для настройки мониторинга)
output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "backend_address_pool_fe_id" {
  value = one(
    [for pool in azurerm_application_gateway.appgw.backend_address_pool :
    pool.id if pool.name == local.backend_address_pool_name_fe]
  )
}

output "backend_address_pool_be_id" {
  value = one(
    [for pool in azurerm_application_gateway.appgw.backend_address_pool :
    pool.id if pool.name == local.backend_address_pool_name_be]
  )
}
