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

  # Email receiver
  dynamic "email_receiver" {
    for_each = var.notification_email != "" ? [1] : []
    content {
      name          = "email-notifications"
      email_address = var.notification_email
    }
  }

  # Telegram webhook receiver (via Logic App)
  dynamic "webhook_receiver" {
    for_each = var.telegram_bot_token != "" && var.telegram_chat_id != "" ? [1] : []
    content {
      name        = "telegram-notifications"
      service_uri = azurerm_logic_app_workflow.telegram_alert[0].endpoint
    }
  }
}

# Logic App for beautiful Telegram notifications
resource "azurerm_logic_app_workflow" "telegram_alert" {
  count               = var.telegram_bot_token != "" && var.telegram_chat_id != "" ? 1 : 0
  name                = "${var.prefix}-telegram-alert"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_logic_app_trigger_http_request" "telegram_alert_trigger" {
  count        = var.telegram_bot_token != "" && var.telegram_chat_id != "" ? 1 : 0
  name         = "azure-monitor-trigger"
  logic_app_id = azurerm_logic_app_workflow.telegram_alert[0].id
  schema = jsonencode({
    type       = "object"
    properties = {}
  })
}

resource "azurerm_logic_app_action_http" "telegram_send" {
  count        = var.telegram_bot_token != "" && var.telegram_chat_id != "" ? 1 : 0
  name         = "send-telegram"
  logic_app_id = azurerm_logic_app_workflow.telegram_alert[0].id
  method       = "POST"
  uri          = "https://api.telegram.org/bot${var.telegram_bot_token}/sendMessage"
  body = jsonencode({
    chat_id    = var.telegram_chat_id
    text       = "🚨 *Azure Alert Triggered* 🚨\n\n📊 *Alert Details:*\n━━━━━━━━━━━━━━━━━━━━\n🔔 *Status:* Fired\n⏰ *Time:* @{triggerBody()?['data']?['firedDateTime']}\n🏷️ *Resource:* @{triggerBody()?['data']?['resourceName']}\n📦 *Resource Type:* @{triggerBody()?['data']?['resourceType']}\n👥 *Resource Group:* @{triggerBody()?['data']?['resourceGroupName']}\n📝 *Reason:* @{triggerBody()?['data']?['condition']?['allOf']?[0]?['metricName']} is @{triggerBody()?['data']?['condition']?['allOf']?[0]?['operator']} @{triggerBody()?['data']?['condition']?['allOf']?[0]?['threshold']} (current: @{triggerBody()?['data']?['condition']?['allOf']?[0]?['metricValue']})\n━━━━━━━━━━━━━━━━━━━━\n\n🔗 *View in Azure Portal:*\nhttps://portal.azure.com/#@/resource@{triggerBody()?['data']?['resourceId']}\n━━━━━━━━━━━━━━━━━━━━\n\n🤖 *Powered by Azure Monitor & Terraform*"
    parse_mode = "Markdown"
  })
  headers = {
    Content-Type = "application/json"
  }
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

# 2. VMSS FE CPU Alert
resource "azurerm_monitor_metric_alert" "vmss_fe_cpu" {
  name                = "${var.prefix}-alert-vmss-fe-cpu-musa"
  resource_group_name = var.resource_group_name
  scopes              = [var.vmss_fe_id]
  description         = "Action will be triggered when CPU Percentage is greater than 70%"
  severity            = 2
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}

# 3. VMSS BE CPU Alert
resource "azurerm_monitor_metric_alert" "vmss_be_cpu" {
  name                = "${var.prefix}-alert-vmss-be-cpu-musa"
  resource_group_name = var.resource_group_name
  scopes              = [var.vmss_be_id]
  description         = "Action will be triggered when CPU Percentage is greater than 70%"
  severity            = 2
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
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
