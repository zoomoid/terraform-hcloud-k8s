output "hcl" {
  description = "admin.conf kubeconfig as HCL"
  value       = local.kubeconfig_hcl
}

output "yaml" {
  description = "admin.conf kubeconfig as YAML"
  value       = local.kubeconfig_yaml
}

output "cluster_ca_certificate" {
  description = "Kubeconfig Cluster CA certificate"
  value       = local.cluster_ca_certificate
}

output "client_key" {
  description = "Kubeconfig Client Key"
  value       = local.client_key
}

output "client_certificate" {
  description = "Kubeconfig Client Certificate"
  value       = local.client_certificate
}

output "cluster_endpoint" {
  description = "Kubeconfig Cluster Server"
  value       = local.cluster_endpoint
}
