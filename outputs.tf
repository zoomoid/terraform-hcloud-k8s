output "nodes_ipv4" {
  value = local.node_ipv4_addresses
  description = "Node IPv4 addresses that were created"
}

output "nodes_ipv6" {
  value = local.node_ipv6_addresses
  description = "Node IPv6 addresses that were created"
}

output "kubeconfig_yaml" {
  value = module.kubeconfig.yaml
  description = "The (super)admin kubeconfig created on the leader of the control-plane. You might want to replace this with a less permissive kubeconfig afterwards..."
}
