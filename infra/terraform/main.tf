resource "azurerm_resource_group" "rg" {
  name     = "musa-project2-rg" 
  location = var.location       
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.prefix}-appgw-pip"          
  resource_group_name = azurerm_resource_group.rg.name     
  location            = azurerm_resource_group.rg.location 
  allocation_method   = "Static"                           
  sku                 = "Standard"                         
}

module "networking" {
  source                       = "./modules/networking"               
  prefix                       = var.prefix                           
  location                     = azurerm_resource_group.rg.location   
  resource_group_name          = azurerm_resource_group.rg.name       
  vnet_address_space           = var.vnet_address_space               
  appgw_subnet_prefix          = var.appgw_subnet_prefix             
  fe_integration_subnet_prefix = var.fe_integration_subnet_prefix     
  be_integration_subnet_prefix = var.be_integration_subnet_prefix    
  pep_subnet_prefix            = var.pep_subnet_prefix                
  ops_subnet_prefix            = var.ops_subnet_prefix               
}

module "database" {
  source              = "./modules/database"
  prefix              = var.prefix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.networking.vnet_id          
  pep_subnet_id       = module.networking.pep_subnet_id    
  sql_admin_username  = var.sql_admin_username             
  sql_admin_password  = var.sql_admin_password             
  db_name             = var.db_name                        
}


module "app_gateway" {
  source              = "./modules/app_gateway"
  prefix              = var.prefix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  appgw_subnet_id     = module.networking.appgw_subnet_id     
  appgw_public_ip_id  = azurerm_public_ip.appgw_pip.id        
  fe_app_fqdn         = module.app_service.fe_app_default_hostname # Внутренний адрес frontend-приложения
  be_app_fqdn         = module.app_service.be_app_default_hostname # Внутренний адрес backend-приложения


  depends_on = [module.app_service]
}


module "app_service" {
  source                   = "./modules/app_service"
  prefix                   = var.prefix
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  vnet_id                  = module.networking.vnet_id                  
  pep_subnet_id            = module.networking.pep_subnet_id           
  fe_integration_subnet_id = module.networking.fe_integration_subnet_id 
  be_integration_subnet_id = module.networking.be_integration_subnet_id 
  appgw_public_ip_address  = azurerm_public_ip.appgw_pip.ip_address     
  sql_server_fqdn          = module.database.sql_server_fqdn            
  db_name                  = module.database.database_name              
  sql_admin_username       = var.sql_admin_username                   
  sql_admin_password       = var.sql_admin_password                     
  sku_name                 = var.app_service_sku                        
}


module "sonarqube_vm" {
  source              = "./modules/sonarqube_vm"
  prefix              = var.prefix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ops_subnet_id       = module.networking.ops_subnet_id 
  vm_ssh_public_key   = var.vm_ssh_public_key         
}

# (Application Insights и Log Analytics)
module "monitoring" {
  source              = "./modules/monitoring"
  prefix              = var.prefix
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  appgw_id            = module.app_gateway.appgw_id     # ID балансировщика для сбора логов
  app_service_plan_id = module.app_service.fe_app_name  # Имя frontend приложения (используется как привязка)
  sql_server_id       = module.database.sql_server_id   # ID сервера БД
  sql_database_id     = "${module.database.sql_server_id}/databases/${module.database.database_name}" # Полный путь до самой базы
}
