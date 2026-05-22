output "web_app_id" {
  value = azurerm_linux_web_app.app.id
}

output "default_hostname" {
  value = azurerm_linux_web_app.app.default_hostname
}

output "app_name" {
  value = azurerm_linux_web_app.app.name
}
