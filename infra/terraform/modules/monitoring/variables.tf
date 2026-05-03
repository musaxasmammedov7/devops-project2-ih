variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "appgw_id" {
  type = string
}

variable "vmss_fe_id" {
  type = string
}

variable "vmss_be_id" {
  type = string
}

variable "sql_server_id" {
  type = string
}

variable "sql_database_id" {
  type = string
}

variable "telegram_bot_token" {
  type        = string
  default     = ""
  description = "Telegram bot token for notifications"
}

variable "telegram_chat_id" {
  type        = string
  default     = ""
  description = "Telegram chat ID for notifications"
}

variable "notification_email" {
  type        = string
  default     = ""
  description = "Email address for notifications"
}
