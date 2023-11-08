locals {
  allowed_ips = concat([
    var.network_ipv4_cidr,
    "127.0.0.1/32",
    ], 
    var.node_ipv6_addresses,
    [for addr in var.node_ipv4_addresses: format("%s/32", addr)],
  )

  firewall_rules = concat([
    {
      direction  = "in"
      protocol   = "tcp"
      port       = "any"
      source_ips = local.allowed_ips
    },
    {
      direction  = "in"
      protocol   = "udp"
      port       = "any"
      source_ips = local.allowed_ips
    },
    {
      direction  = "in"
      protocol   = "icmp"
      source_ips = local.allowed_ips
    },
  ], var.static_firewall_rules)
}
