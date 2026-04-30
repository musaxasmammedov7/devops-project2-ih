resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Создаем Application Insights — сервис для мониторинга производительности самого приложения (APM)
resource "azurerm_application_insights" "appinsights" {
  name                = "${var.prefix}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# Создаем Action Group — это группа действий, которая срабатывает при тревоге (Alert)
resource "azurerm_monitor_action_group" "ag" {
  name                = "${var.prefix}-actiongroup"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  # Minimal action group to satisfy requirement (you can add email receivers later)
}

# 1. App Gateway Backend Health Alert
resource "azurerm_monitor_metric_alert" "appgw_health" {
  name                = "${var.prefix}-alert-appgw-health"
  resource_group_name = var.resource_group_name
  scopes              = [var.appgw_id]
  description         = "Action will be triggered when Unhealthy Host Count > 0"
  severity            = 1
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  # Что делать при тревоге (вызвать Action Group)
  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# 2. App Service CPU Alert
resource "azurerm_monitor_metric_alert" "app_cpu" {
  name                = "${var.prefix}-alert-app-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_plan_id]
  description         = "Action will be triggered when CPU Percentage is greater than 70%"
  severity            = 2
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# 3. SQL Database CPU Alert (DTU/vCore approximation)
resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "${var.prefix}-alert-sql-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.sql_database_id]
  description         = "Action will be triggered when SQL CPU > 80%"
  severity            = 2
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}
