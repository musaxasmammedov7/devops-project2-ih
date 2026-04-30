# Создаем App Service Plan (план обслуживания) - это своего рода "серверная ферма",
# которая выделяет вычислительные ресурсы (CPU, RAM) и ОС (в нашем случае Linux) 
# для запуска наших веб-приложений.
resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.prefix}-fe-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.asp.id

  public_network_access_enabled = false
  virtual_network_subnet_id     = var.fe_integration_subnet_id

  site_config {
    application_stack {
      node_version = "20-lts"
    }
    app_command_line = "pm2 serve /home/site/wwwroot/dist --no-daemon --spa"
  }

  app_settings = {
    "VITE_API_BASE_URL" = "https://${var.appgw_public_ip_address}/api"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_linux_web_app" "backend" {
  name                = "${var.prefix}-be-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.asp.id

  public_network_access_enabled = false
  virtual_network_subnet_id     = var.be_integration_subnet_id

  site_config {
    application_stack {
      java_server         = "JAVA"
      java_server_version = "21"
      java_version        = "21"
    }
  }

  app_settings = {
    "SPRING_PROFILES_ACTIVE" = "azure"
    "DB_HOST"                = var.sql_server_fqdn
    "DB_PORT"                = "1433"
    "DB_NAME"                = var.db_name
    "DB_USERNAME"            = var.sql_admin_username
    "DB_PASSWORD"            = var.sql_admin_password
    "DB_DRIVER"              = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# Private DNS Zone for App Services
resource "azurerm_private_dns_zone" "app_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_vnet_link" {
  name                  = "${var.prefix}-app-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_dns_zone.name
  virtual_network_id    = var.vnet_id
}

# Private Endpoints
resource "azurerm_private_endpoint" "fe_pe" {
  name                = "${var.prefix}-fe-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pep_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-fe-privatelink"
    private_connection_resource_id = azurerm_linux_web_app.frontend.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "app-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_dns_zone.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.app_vnet_link]
}

resource "azurerm_private_endpoint" "be_pe" {
  name                = "${var.prefix}-be-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pep_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-be-privatelink"
    private_connection_resource_id = azurerm_linux_web_app.backend.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "app-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_dns_zone.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.app_vnet_link]
}
