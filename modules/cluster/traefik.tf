resource "helm_release" "traefik" {
  count = var.enable_traefik ? 1 : 0

  depends_on = [
    helm_release.cilium,
    helm_release.metallb,
    kubectl_manifest.metallb_ipaddresspool,
    kubectl_manifest.metallb_l2advertisement,
    kubectl_manifest.gateway_api_crds
  ]

  create_namespace = true
  namespace        = "traefik"

  version = "^25.0.0"

  name = "traefik"

  chart      = "traefik"
  repository = "https://traefik.github.io/charts"

  set {
    name  = "ports.websecure.http3.enabled"
    value = true
  }
  set {
    name  = "ports.websecure.http3.advertisedPort"
    value = 443
  }
  # set {
  #   name = "experimental.kubernetesGateway.enabled"
  #   value = true
  # }
  # set {
  #   name = "experimental.kubernetesGateway.namespacePolicy"
  #   value = "All"
  # }
  # set {
  #   name = "experimental.kubernetesGateway.namespace"
  #   value = "default"
  # }
}
