resource "azurerm_mssql_server" "sql" {
  name                         = "${var.prefix}-sqlserver"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  name      = var.db_name
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0" # Basic/Standard S0 is fine for this project
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.prefix}-sql-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = var.vnet_id
}

# Private Endpoint
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${var.prefix}-sql-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pep_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-sql-privatelink"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet_link]
}
