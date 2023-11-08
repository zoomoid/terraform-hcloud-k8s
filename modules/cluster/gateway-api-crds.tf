resource "kubectl_manifest" "gateway_api_crds" {
  count = var.enable_gateway_api ? 1 : 0

  depends_on = [
    # Adding cilium here creates a cyclic dependency because cilium's operator requires
    # the CRDS to be available, while the admission controller requires working
    # pod sandboxes (which isn't necessarily given before cilium is up)
    # helm_release.cilium
  ]
  server_side_apply = true

  yaml_body = file("${path.module}/templates/gateway_api_crds_1.0.0.yaml")
}