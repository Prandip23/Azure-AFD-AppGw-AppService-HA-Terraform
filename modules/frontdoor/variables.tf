variable "afd_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "endpoint_name" {
  type = string
}

variable "origin_group_name" {
  type = string
}

variable "origins" {
  type = map(object({
    host_name = string
    priority  = number
    weight    = number
  }))
}
