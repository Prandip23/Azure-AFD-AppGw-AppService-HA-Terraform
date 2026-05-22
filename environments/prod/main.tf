module "resource_group" {
  source              = "../../modules/resource-group"
  resource_group_name = var.resource_group_name
  location            = var.location_primary
}

module "network_central" {
  source              = "../../modules/network"
  vnet_name           = "vnet-cin"
  location            = var.location_primary
  resource_group_name = var.resource_group_name
  address_space       = ["10.10.0.0/16"]

  subnets = {
    appgw-subnet            = "10.10.1.0/24"
    private-endpoint-subnet = "10.10.2.0/24"
  }

  depends_on = [module.resource_group]
}

module "network_south" {
  source              = "../../modules/network"
  vnet_name           = "vnet-sin"
  location            = var.location_secondary
  resource_group_name = var.resource_group_name
  address_space       = ["10.20.0.0/16"]

  subnets = {
    appgw-subnet            = "10.20.1.0/24"
    private-endpoint-subnet = "10.20.2.0/24"
  }

  depends_on = [module.resource_group]
}

resource "azurerm_network_security_group" "appgw_subnet_central" {
  name                = "nsg-appgw-cin"
  location            = var.location_primary
  resource_group_name = var.resource_group_name

  depends_on = [module.network_central]
}

resource "azurerm_network_security_group" "appgw_subnet_south" {
  name                = "nsg-appgw-sin"
  location            = var.location_secondary
  resource_group_name = var.resource_group_name

  depends_on = [module.network_south]
}

resource "azurerm_subnet_network_security_group_association" "appgw_subnet_central" {
  subnet_id                 = module.network_central.subnet_ids["appgw-subnet"]
  network_security_group_id = azurerm_network_security_group.appgw_subnet_central.id
}

resource "azurerm_subnet_network_security_group_association" "appgw_subnet_south" {
  subnet_id                 = module.network_south.subnet_ids["appgw-subnet"]
  network_security_group_id = azurerm_network_security_group.appgw_subnet_south.id
}

module "private_dns" {
  source              = "../../modules/private-dns"
  resource_group_name = var.resource_group_name
  vnet_ids = {
    central = module.network_central.vnet_id
    south   = module.network_south.vnet_id
  }

  depends_on = [module.network_central, module.network_south]
}

module "app_service_plan_central" {
  source              = "../../modules/app-service-plan"
  plan_name           = "asp-cin-active"
  resource_group_name = var.resource_group_name
  location            = var.location_primary

  depends_on = [module.resource_group]
}

module "app_service_plan_south" {
  source              = "../../modules/app-service-plan"
  plan_name           = "asp-sin-standby"
  resource_group_name = var.resource_group_name
  location            = var.location_secondary

  depends_on = [module.resource_group]
}

module "app_service_central" {
  source              = "../../modules/app-service"
  app_name            = "app-cin-active-tf"
  resource_group_name = var.resource_group_name
  location            = var.location_primary
  service_plan_id     = module.app_service_plan_central.service_plan_id

  depends_on = [module.app_service_plan_central]
}

module "app_service_south" {
  source              = "../../modules/app-service"
  app_name            = "app-sin-standby-tf"
  resource_group_name = var.resource_group_name
  location            = var.location_secondary
  service_plan_id     = module.app_service_plan_south.service_plan_id

  depends_on = [module.app_service_plan_south]
}

module "private_endpoint_central" {
  source                         = "../../modules/private-endpoint"
  private_endpoint_name          = "pe-app-cin"
  resource_group_name            = var.resource_group_name
  location                       = var.location_primary
  subnet_id                      = module.network_central.subnet_ids["private-endpoint-subnet"]
  private_connection_resource_id = module.app_service_central.web_app_id
  private_dns_zone_id            = module.private_dns.private_dns_zone_id

  depends_on = [module.private_dns, module.app_service_central]
}

module "private_endpoint_south" {
  source                         = "../../modules/private-endpoint"
  private_endpoint_name          = "pe-app-sin"
  resource_group_name            = var.resource_group_name
  location                       = var.location_secondary
  subnet_id                      = module.network_south.subnet_ids["private-endpoint-subnet"]
  private_connection_resource_id = module.app_service_south.web_app_id
  private_dns_zone_id            = module.private_dns.private_dns_zone_id

  depends_on = [module.private_dns, module.app_service_south]
}

module "app_gateway_central" {
  source              = "../../modules/app-gateway"
  appgw_name          = "appgw-cin-active"
  resource_group_name = var.resource_group_name
  location            = var.location_primary
  subnet_id           = module.network_central.subnet_ids["appgw-subnet"]
  backend_hostname    = module.app_service_central.default_hostname
  public_ip_dns_label = "appgw-cin-active-tf"

  depends_on = [
    module.private_endpoint_central,
    azurerm_subnet_network_security_group_association.appgw_subnet_central,
    azurerm_network_security_rule.appgw_gatewaymanager_central,
    azurerm_network_security_rule.appgw_frontdoor_backend_central
  ]
}

module "app_gateway_south" {
  source              = "../../modules/app-gateway"
  appgw_name          = "appgw-sin-standby"
  resource_group_name = var.resource_group_name
  location            = var.location_secondary
  subnet_id           = module.network_south.subnet_ids["appgw-subnet"]
  backend_hostname    = module.app_service_south.default_hostname
  public_ip_dns_label = "appgw-sin-standby-tf"

  depends_on = [
    module.private_endpoint_south,
    azurerm_subnet_network_security_group_association.appgw_subnet_south,
    azurerm_network_security_rule.appgw_gatewaymanager_south,
    azurerm_network_security_rule.appgw_frontdoor_backend_south
  ]
}

module "frontdoor" {
  source              = "../../modules/frontdoor"
  afd_name            = "afd-active-standby-tf"
  endpoint_name       = "afd-active-standby-ep"
  origin_group_name   = "appgw-origins"
  resource_group_name = var.resource_group_name

  origins = {
    central = {
      host_name = module.app_gateway_central.public_ip_fqdn
      priority  = 1
      weight    = 1000
    }
    south = {
      host_name = module.app_gateway_south.public_ip_fqdn
      priority  = 2
      weight    = 500
    }
  }

  depends_on = [module.app_gateway_central, module.app_gateway_south]
}

resource "azurerm_network_security_rule" "appgw_gatewaymanager_central" {
  name                        = "Allow-GatewayManager-65200-65535"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_subnet_central.name

  depends_on = [azurerm_subnet_network_security_group_association.appgw_subnet_central]
}

resource "azurerm_network_security_rule" "appgw_frontdoor_backend_central" {
  name                        = "Allow-AzureFrontDoor-Backend-Http"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_subnet_central.name

  depends_on = [azurerm_subnet_network_security_group_association.appgw_subnet_central]
}

resource "azurerm_network_security_rule" "appgw_gatewaymanager_south" {
  name                        = "Allow-GatewayManager-65200-65535"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_subnet_south.name

  depends_on = [azurerm_subnet_network_security_group_association.appgw_subnet_south]
}

resource "azurerm_network_security_rule" "appgw_frontdoor_backend_south" {
  name                        = "Allow-AzureFrontDoor-Backend-Http"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_subnet_south.name

  depends_on = [azurerm_subnet_network_security_group_association.appgw_subnet_south]
}
