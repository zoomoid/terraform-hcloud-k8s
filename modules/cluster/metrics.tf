resource "helm_release" "metrics-server" {
  count = var.enable_metrics_server ? 1 : 0

  name = "metrics-server"

  depends_on = [
    helm_release.cilium,
  ]

  version = "3.11.0"

  wait = false

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}
