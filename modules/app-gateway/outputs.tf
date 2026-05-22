output "public_ip_fqdn" {
  value = azurerm_public_ip.pip.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}
