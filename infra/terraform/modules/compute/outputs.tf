output "vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
  description = "The ID of the Virtual Machine Scale Set"
}

output "principal_id" {
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
  description = "The Principal ID of the VMSS System Assigned Managed Identity"
}
