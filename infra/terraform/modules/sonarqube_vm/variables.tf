# Общий префикс для названий ресурсов
variable "prefix" {
  type = string
}

# Регион развертывания
variable "location" {
  type = string
}

# Имя ресурсной группы
variable "resource_group_name" {
  type = string
}

# ID подсети DevOps, в которой будет создана ВМ
variable "ops_subnet_id" {
  type = string
}

# Имя пользователя (администратора) ВМ
variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

# Публичный SSH-ключ для доступа к ВМ
variable "vm_ssh_public_key" {
  type = string
}
