resource "helm_release" "tbctrl" {
  count = var.enable_kubelet_tls_bootstrapping_controller? 1 : 0

  name       = "tbctrl"
  chart      = "tbctrl"
  repository = "https://helm.zoomoid.dev"

  namespace = "kube-system"
  version   = "0.5.1"

  wait = false

  set {
    name = "k8s.host"
    value = var.cluster_endpoint
  }

  set {
    name = "k8s.port"
    value = "6443"
  }
}