output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "fe_subnet_id" {
  value = azurerm_subnet.fe.id
}

output "be_subnet_id" {
  value = azurerm_subnet.be.id
}

output "pep_subnet_id" {
  value = azurerm_subnet.pep.id
}

output "ops_subnet_id" {
  value = azurerm_subnet.ops.id
}
