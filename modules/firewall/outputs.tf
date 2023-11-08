output "firewall_id" {
  description = "ID of the network's firewall"
  value       = hcloud_firewall.kubernetes.id
}