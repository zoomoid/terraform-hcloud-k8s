resource "hcloud_network" "kubernetes" {
  name     = "kubernetes"
  ip_range = var.ipv4_range
}

resource "hcloud_network_subnet" "kubernetes" {
  network_id   = hcloud_network.kubernetes.id
  network_zone = var.network_zone
  ip_range     = var.ipv4_subnet_range
  type         = "cloud"
}
