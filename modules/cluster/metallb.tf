resource "helm_release" "metallb" {
  count = var.enable_metallb ? 1 : 0

  depends_on = [
    helm_release.cilium
  ]

  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"

  wait = false

  create_namespace = true
  namespace        = "metallb-system"
}

resource "kubectl_manifest" "metallb_ipaddresspool" {
  depends_on = [
    helm_release.metallb
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/metallb_ip_address_pool.yaml.tftpl", {
    node_ipv4_addresses = var.node_ipv4_lb_cidrs
    # node_ipv6_addresses = var.node_ipv6_lb_cidrs
    node_ipv6_addresses = []
  })
}

resource "kubectl_manifest" "metallb_l2advertisement" {
  depends_on = [
    helm_release.metallb
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/metallb_l2_advertisement.yaml.tftpl", {})
}
