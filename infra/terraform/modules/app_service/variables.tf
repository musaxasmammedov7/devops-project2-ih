variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "pep_subnet_id" {
  type = string
}

variable "fe_integration_subnet_id" {
  type = string
}

variable "be_integration_subnet_id" {
  type = string
}

variable "sql_server_fqdn" {
  type = string
}

variable "db_name" {
  type = string
}

variable "sql_admin_username" {
  type = string
  sensitive = true
}

variable "sql_admin_password" {
  type = string
  sensitive = true
}

variable "appgw_public_ip_address" {
  type = string
}

variable "sku_name" {
  type = string
  default = "P1v3"
}
