output "nodes_ipv4" {
  value = local.node_ipv4_addresses
}

output "nodes_ipv6" {
  value = local.node_ipv6_addresses
}

# output "nodes_ipv4_lb_cidrs" {
#   value = local.node_ipv4_lb_cidrs
# }

# output "nodes_ipv6_lb_cidrs" {
#   value = local.node_ipv6_lb_cidrs
# }

# output "ca_cert_hash" {
#   value = local.ca_cert_hash
# }

output "kubeconfig_yaml" {
  value = module.kubeconfig.yaml
}

# output "kubeconfig_hcl" {
#   value = module.kubeconfig.hcl
# } 