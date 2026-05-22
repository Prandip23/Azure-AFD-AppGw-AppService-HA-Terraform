variable "zone_name" {
  type    = string
  default = "privatelink.azurewebsites.net"
}

variable "resource_group_name" {
  type = string
}

variable "vnet_ids" {
  type = map(string)
}
