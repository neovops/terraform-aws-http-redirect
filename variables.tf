variable "redirect_mapping" {
  type        = map(string)
  description = "Redirect mapping"
}

variable "dns_zone" {
  type        = string
  description = "Route53 DNS zone name"
}

variable "resources_name" {
  type        = string
  default     = "http-redirect"
  description = "Resources name. Necessary for multiple instances of this module"
}
