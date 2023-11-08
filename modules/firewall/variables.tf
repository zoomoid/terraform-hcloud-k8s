variable "nodes" {
  type    = map(any)
  default = {}
}

variable "name" {
  type = string
  description = "Name of the firewall object at the Hetzner Cloud API"
  default = "kubernetes"
}

variable "network_ipv4_cidr" {
  type = string
  default = "10.0.0.0/8"
  description = "CIDR of the virtual private network created for IPv4 networking between nodes"  
}

variable "node_ipv6_addresses" {
  type    = list(string)
  default = []
}

variable "node_ipv4_addresses" {
  type    = list(string)
  default = []
}

variable "static_firewall_rules" {
  type = list(object({
    direction = string
    protocol = string
    port = optional(string)
    source_ips = list(string)
  }))
}