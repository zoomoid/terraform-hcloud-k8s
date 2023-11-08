locals {
  control_plane_nodes = var.control_plane_nodes
  worker_nodes        = var.worker_nodes

  nodes = merge(module.control_plane, module.workers)

  node_ipv4_addresses = values(local.nodes)[*].ipv4_address
  node_ipv6_addresses = values(local.nodes)[*].ipv6_address

  # This is hacky: we use each Node IPv4 address as a /32 subnet (i.e., one single address)
  # Technically this should not work (according to some people who know IP better than I do)
  # however, it has worked for some years now...
  node_ipv4_cidrs = [for addr in local.node_ipv4_addresses : format("%s/32", addr)]

  node_ipv6_cidrs = values(local.nodes)[*].ipv6_network

  node_ipv4_lb_cidrs = [for addr in local.node_ipv4_cidrs : cidrsubnet(addr, 0, 0)]
  node_ipv6_lb_cidrs = [for addr in local.node_ipv6_cidrs : cidrsubnet(addr, 56, 0)]

  cluster_endpoint = format("%s.%s:%d", var.dns_cluster_subdomain, var.dns_root, var.control_plane_api_server_port)

  fleet_prefix   = format("%s.%s", var.dns_fleet_subdomain, var.dns_root)
  cluster_prefix = format("%s.%s", var.dns_cluster_subdomain, var.dns_root)
}
