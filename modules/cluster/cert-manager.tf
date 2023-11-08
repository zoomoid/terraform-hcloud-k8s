resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  depends_on = [
    helm_release.cilium,
    kubernetes_deployment_v1.hcloud_cloud_controller_manager,
  ]

  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"

  create_namespace = true
  namespace        = "cert-manager"

  version = "v1.12.4"

  wait = false

  set {
    name  = "installCRDs"
    value = true
  }

  # set {
  #   name  = "extraArgs"
  #   value = "{--feature-gates=ExperimentalGatewayAPISupport=true}"
  #   # value = "{--feature-gates=CSIInlineVolume=true}"
  # }
}

resource "helm_release" "cert_manager_csi_driver" {
  count = var.enable_cert_manager_csi_driver ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]

  name       = "cert-manager-csi-driver"
  chart      = "cert-manager-csi-driver"
  repository = "https://charts.jetstack.io"

  # create_namespace = true
  namespace = "cert-manager"

  version = "v0.5.0"

  wait = true
}

resource "kubernetes_secret" "cloudflare_api_key" {
  count = var.enable_cloudflare_dns ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]

  metadata {
    name      = "cloudflare-api-key"
    namespace = "cert-manager"
  }

  type = "Opaque"

  data = {
    "api-key" = var.cloudflare_api_key
  }
}

resource "kubernetes_secret" "google_cloud_platform_eab" {
  count = var.enable_google_trust_services_http01 || var.enable_google_trust_services_dns01 ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]

  metadata {
    name      = "google-cloud-platform-eab"
    namespace = "cert-manager"
  }

  type = "Opaque"

  data = {
    "eab-kid"      = var.google_cloud_platform_eab_kid,
    "eab-hmac-key" = var.google_cloud_platform_eab_hmac_key
  }
}

resource "kubectl_manifest" "letsencrypt_dns01_cluster_issuer" {
  count = var.enable_lets_encrypt_dns01 ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/cert_manager_letsencrypt_dns01_clusterissuer.yaml.tftpl", {
    cloudflare_email = var.cloudflare_email,
    lets_encrypt_email = var.lets_encrypt_email
  })
}

resource "kubectl_manifest" "letsencrypt_http01_cluster_issuer" {
  count = var.enable_lets_encrypt_http01 ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/cert_manager_letsencrypt_http01_clusterissuer.yaml.tftpl", {
    lets_encrypt_email = var.lets_encrypt_email,
    ingress_class_name = var.cert_manager_http01_ingress_class_name
  })
}

resource "kubectl_manifest" "google_trust_services_dns01_cluster_issuer" {
  count = var.enable_google_trust_services_dns01 ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/cert_manager_google_trust_services_dns01_clusterissuer.yaml.tftpl", {
    key_id = var.google_cloud_platform_eab_kid,
    cloudflare_email = var.cloudflare_email,
    google_cloud_platform_email = var.google_cloud_platform_email,
  })
}

resource "kubectl_manifest" "google_trust_services_http01_cluster_issuer" {
  count = var.enable_google_trust_services_http01 ? 1 : 0

  depends_on = [
    helm_release.cert_manager
  ]
  apply_only = true

  yaml_body = templatefile("${path.module}/templates/cert_manager_google_trust_services_http01_clusterissuer.yaml.tftpl", {
    key_id = var.google_cloud_platform_eab_kid,
    google_cloud_platform_email = var.google_cloud_platform_email,
    ingress_class_name = var.cert_manager_http01_ingress_class_name
  })
}
