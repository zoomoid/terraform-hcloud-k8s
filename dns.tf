module "dns" {
  count = var.enable_cloudflare_dns ? 1 : 0

  source = "./modules/dns"


  depends_on = [
    module.control_plane,
    module.workers
  ]

  cloudflare_zone_id = var.cloudflare_zone_id

  nodes         = local.nodes
  control_plane = module.control_plane

  dns_cluster = var.dns_cluster_subdomain
  dns_fleet   = var.dns_fleet_subdomain
  dns_root    = var.dns_root
}