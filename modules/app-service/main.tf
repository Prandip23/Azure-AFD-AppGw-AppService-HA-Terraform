resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id

  site_config {
    always_on = true
    application_stack {
      node_version = "20-lts"
    }
  }

  public_network_access_enabled = false
}
