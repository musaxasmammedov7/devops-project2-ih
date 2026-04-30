# Экспортируем ключ Instrumentation Key для подключения приложений к Application Insights
output "instrumentation_key" {
  value     = azurerm_application_insights.appinsights.instrumentation_key
  sensitive = true
}

# Экспортируем Connection String для Application Insights
output "app_insights_connection_string" {
  value     = azurerm_application_insights.appinsights.connection_string
  sensitive = true
}
