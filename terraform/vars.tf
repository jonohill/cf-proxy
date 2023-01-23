variable "name" {
    type = string
    description = "Name for the resources to be created"
}

variable "zone_name" {
    type = string
    description = "DNS Zone e.g. example.com"
}

variable "subdomain" {
    type = string
    description = "Subdomain to bind the script to e.g. api"
}

variable "upstream_url" {
    type = string
    description = "The URL that requests will be sent to"
}
