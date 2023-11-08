resource "helm_release" "ingress_nginx" {

  count = var.enable_ingress_nginx ? 1 : 0

  depends_on = [
    helm_release.cilium,
    helm_release.metallb,
    kubectl_manifest.metallb_ipaddresspool,
    kubectl_manifest.metallb_l2advertisement
  ]

  create_namespace = true
  namespace = "ingress-nginx"

  name = "ingress-nginx"

  chart = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"

  set {
    name = "defaultBackend.enabled"
    value = true
  }

  set {
    name = "defaultBackend.image.image"
    value = "defaultbackend-arm64"
  }

  set {
    name = "controller.ingressClassResource.default"
    value = true
  }
}