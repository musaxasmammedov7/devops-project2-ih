variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "burger"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "appgw_subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "fe_integration_subnet_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "be_integration_subnet_prefix" {
  type    = string
  default = "10.0.3.0/24"
}

variable "pep_subnet_prefix" {
  type    = string
  default = "10.0.4.0/24"
}

variable "ops_subnet_prefix" {
  type    = string
  default = "10.0.5.0/24"
}

variable "sql_admin_username" {
  description = "Admin username for SQL server"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Admin password for SQL server"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "burgerbuilder"
}

variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "P1v3"
}

variable "vm_admin_username" {
  description = "Admin username for SonarQube VM"
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for SonarQube VM"
  type        = string
}
