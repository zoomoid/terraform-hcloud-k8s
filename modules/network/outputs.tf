output "ipv4_subnet_id" {
  description = "ID of the subnet to add servers to"
  value       = hcloud_network_subnet.kubernetes.id
}

output "network_id" {
  description = "ID of the private network"
  value       = hcloud_network.kubernetes.id
}
