output "frontdoor_endpoint" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}"
}
