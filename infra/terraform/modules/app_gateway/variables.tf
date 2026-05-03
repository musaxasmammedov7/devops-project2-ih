variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "appgw_subnet_id" {
  type = string
}

variable "appgw_public_ip_id" {
  type = string
}

variable "appgw_identity_id" {
  type = string
}

variable "custom_domain_name" {
  type    = string
  default = ""
}

variable "appgw_ssl_certificate_key_vault_secret_id" {
  type    = string
  default = ""
}

