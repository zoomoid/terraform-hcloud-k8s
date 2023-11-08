resource "helm_release" "tetragon" {
  count = var.enable_tetragon ? 1 : 0

  depends_on = [
    helm_release.cilium
  ]

  name       = "tetragon"
  chart      = "tetragon"
  repository = "https://helm.cilium.io/"

  namespace = "kube-system"

  wait = true
}