variable "prefix" {
  description = "Prefix for all resources" # Описание переменной
  type        = string                     # Тип переменной - строка
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}

# (Virtual Network)
variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16" # Например, от 10.0.0.0 до 10.0.255.255
}

variable "appgw_subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

# Frontend
variable "fe_subnet_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

# Backend
variable "be_subnet_prefix" {
  type    = string
  default = "10.0.3.0/24"
}

#  Private Endpoints (приватных точек доступа к Web App и БД)
variable "pep_subnet_prefix" {
  type    = string
  default = "10.0.4.0/24"
}

#  SonarQube
variable "ops_subnet_prefix" {
  type    = string
  default = "10.0.5.0/24"
}


variable "sql_admin_username" {
  description = "Admin username for SQL server"
  type        = string
  sensitive   = true # Помечено как конфиденциальное, не будет логироваться в открытом виде
}


variable "sql_admin_password" {
  description = "Admin password for SQL server"
  type        = string
  sensitive   = true # confidential
}


variable "db_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "burgerbuilder"
}


variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "P1v3" # P1v3 - это один из Premium планов (2 ядра, 8GB RAM)
}

variable "custom_domain_name" {
  type    = string
  default = ""
}

variable "appgw_ssl_certificate_key_vault_secret_id" {
  type    = string
  default = ""
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

variable "telegram_bot_token" {
  description = "Telegram bot token for notifications (TF_VAR_telegram_bot_token)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "telegram_chat_id" {
  description = "Telegram chat ID for notifications (TF_VAR_telegram_chat_id)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}
