resource "helm_release" "cilium" {

  depends_on = [
    kubectl_manifest.gateway_api_crds
  ]

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"

  namespace = "kube-system"
  version   = "^1.14.2"

  // otherwise terraform gets stuck 
  wait = true

  values = [ var.cilium_values ]

  # kube-proxy replacement
 set {
    name  = "k8sServiceHost"
    value = var.external_kubernetes_service_host
  }

  set {
    name  = "k8sServicePort"
    value = var.external_kubernetes_service_port
  }

}
