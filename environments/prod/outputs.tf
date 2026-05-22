output "resource_group_name" {
  value = module.resource_group.resource_group_name
}

output "active_region" {
  value = var.location_primary
}

output "standby_region" {
  value = var.location_secondary
}

output "frontdoor_url" {
  value = module.frontdoor.frontdoor_endpoint
}

output "active_origin" {
  value = module.app_gateway_central.public_ip_fqdn
}

output "standby_origin" {
  value = module.app_gateway_south.public_ip_fqdn
}
