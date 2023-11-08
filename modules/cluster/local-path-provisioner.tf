resource "helm_release" "local_path_provisioner" {
  count = var.enable_local_path_provisioner ? 1 : 0

  depends_on = [
    helm_release.cilium
  ]

  create_namespace = true
  namespace = "local-path-storage"

  name = "local-path-provisioner"

  chart = "local-path-provisioner"
  repository = "https://charts.containeroo.ch"
}