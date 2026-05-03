variable "prefix" {
  type        = string
  description = "Prefix for resources"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for VMSS"
}

variable "appgw_backend_pool_ids" {
  type        = list(string)
  description = "List of Application Gateway Backend Pool IDs to attach to VMSS"
  default     = []
}

variable "vm_size" {
  type        = string
  description = "Size of the VMs"
  default     = "Standard_D2ads_v7"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key"
}

variable "custom_data" {
  type        = string
  description = "Base64 encoded custom data (cloud-init)"
  default     = null
}

variable "tier" {
  type        = string
  description = "Tier name (e.g. fe, be)"
  default     = "be"
}
