module "cluster" {
  depends_on = [
    module.kubeconfig,
  ]

  source = "./modules/cluster"

  cluster_endpoint = local.cluster_endpoint

  node_ipv4_addresses = local.node_ipv4_addresses
  node_ipv6_addresses = local.node_ipv6_addresses

  node_ipv6_cidrs = [for cidr in local.node_ipv6_cidrs : cidrsubnet(cidr, 32, 0)]

  node_ipv4_lb_cidrs = local.node_ipv4_lb_cidrs
  node_ipv6_lb_cidrs = local.node_ipv6_lb_cidrs

  enable_cloudflare_dns = var.enable_cloudflare_dns
  cloudflare_api_key    = var.cloudflare_api_key
  cloudflare_email      = var.cloudflare_email

  cilium_values = var.cilium_values

  enable_kubelet_tls_bootstrapping_controller = var.enable_kubelet_tls_bootstrapping_controller

  enable_local_path_provisioner = var.enable_local_path_provisioner

  enable_metallb = var.enable_metallb

  enable_metrics_server = var.enable_metrics_server

  enable_tetragon = var.enable_tetragon

  enable_traefik = var.enable_traefik

  enable_gateway_api = var.enable_gateway_api

  enable_cert_manager            = var.enable_cert_manager
  enable_cert_manager_csi_driver = var.enable_cert_manager_csi_driver

  enable_lets_encrypt_dns01  = var.enable_lets_encrypt_dns01
  enable_lets_encrypt_http01 = var.enable_lets_encrypt_http01
  lets_encrypt_email         = var.lets_encrypt_email

  enable_google_trust_services_dns01  = true
  enable_google_trust_services_http01 = true
  google_cloud_platform_eab_hmac_key  = var.google_cloud_platform_eab_hmac_key
  google_cloud_platform_eab_kid       = var.google_cloud_platform_eab_kid

  enable_hetzner_cloud_controller_manager            = var.enable_hetzner_cloud_controller_manager
  enable_hetzner_cloud_controller_manager_routes     = var.enable_hetzner_cloud_controller_manager_routes
  hetzner_cloud_controller_manager_api_token         = var.hcloud_api_token
  hetzner_cloud_controller_manager_hcloud_network_id = module.network.network_id

  providers = {
    helm       = helm
    kubernetes = kubernetes
    kubectl    = kubectl
  }
}
