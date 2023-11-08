module "network" {
  source = "./modules/network"

  # TODO(zoomoid): create variables for these
  network_zone      = "eu-central"
  ipv4_range        = "10.0.0.0/8"
  ipv4_subnet_range = "10.0.0.0/16"
}

module "firewall" {
  count = var.enable_firewall ? 1 : 0

  source = "./modules/firewall"
  depends_on = [
    module.control_plane,
    module.workers
  ]

  # TODO(zoomoid): create variables for this
  network_ipv4_cidr = "10.0.0.0/8"

  nodes               = local.nodes
  node_ipv6_addresses = local.node_ipv6_cidrs
  node_ipv4_addresses = local.node_ipv4_addresses

  static_firewall_rules = var.static_firewall_rules
}
