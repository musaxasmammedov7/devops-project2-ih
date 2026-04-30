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

variable "sql_admin_username" {
  type = string
  sensitive = true
}

variable "sql_admin_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
  default = "burgerbuilder"
}
