variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "ops_subnet_id" {
  type = string
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_ssh_public_key" {
  type = string
}
