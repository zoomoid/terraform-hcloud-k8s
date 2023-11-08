variable "cluster_endpoint" {
  type        = string
  description = "Hostname at which the control plane is located"
}

variable "node_ipv4_addresses" {
  sensitive   = false
  type        = list(string)
  description = "list of node ipv4 addresses for cilium LB IPAM"
}

variable "node_ipv6_addresses" {
  sensitive   = false
  type        = list(string)
  description = "list of node ipv6 addresses for cilium LB IPAM"
}

variable "node_ipv6_cidrs" {
  sensitive   = false
  type        = list(string)
  description = "list of node ipv6 cidrs for cilium node IPAM"
}

variable "node_ipv4_lb_cidrs" {
  sensitive   = false
  type        = list(string)
  description = "list of node ipv4 cidrs for cilium LB IPAM"
}

variable "node_ipv6_lb_cidrs" {
  sensitive   = false
  type        = list(string)
  description = "list of node ipv6 cidrs for cilium LB IPAM"
}

variable "enable_cloudflare_dns" {
  type        = bool
  default     = false
  description = "Enables Cloudflare DNS records. Requires cloudflare_zone_id, cloudflare_email, and cloudflare_api_key"
  # validation {
  #   condition     = var.enable_cloudflare_dns && length(var.cloudflare_zone_id) > 0 && length(var.cloudflare_email) > 0 && length(var.cloudflare_api_key) > 0
  #   error_message = "enable_cloudflare_dns requires cloudflare_zone_id, cloudflare_email, and cloudflare_api_key"
  # }
}

variable "cloudflare_email" {
  type        = string
  description = "Email to use for Cloudflare authentication"
}

variable "cloudflare_api_key" {
  sensitive   = true
  type        = string
  description = "Cloudflare API token for accessing DNS zones"
}

variable "enable_traefik" {
  type        = bool
  default     = true
  description = "Enables deploying Traefik Ingress controller"
}

variable "enable_ingress_nginx" {
  type        = bool
  default     = false
  description = "Enables deploying ingress-nginx"
}

variable "enable_cert_manager" {
  type        = bool
  default     = true
  description = "Enables cert-manager to be deployed"
}

variable "enable_cert_manager_csi_driver" {
  type        = bool
  default     = true
  description = "Enables cert-manager's CSI driver to be deployed"
}

variable "cert_manager_http01_ingress_class_name" {
  type = string
  default = "traefik"
  description = "Ingress class to use for HTTP01 issuers temporary ingress resources"
}

variable "lets_encrypt_email" {
  type        = string
  description = "Email to use for Let's Encrypt ClusterIssuer"
}

variable "enable_lets_encrypt_http01" {
  type        = bool
  default     = false
  description = "Enables creating cert-manager HTTP01 ClusterIssuers with Let's Encrypt"
}

variable "enable_lets_encrypt_dns01" {
  type        = bool
  default     = false
  description = "Enables creating cert-manager DNS01 ClusterIssuer with Let's Encrypt"
}

variable "enable_google_trust_services_http01" {
  type        = bool
  default     = false
  description = "Enables creating cert-manager HTTP01 ClusterIssuers for Google Trust Services. Requires google_cloud_platform_eab_kid and google_cloud_platform_eab_hmac_key to be provided"
  # validation {
  #   condition     = var.enable_google_trust_services && length(var.google_cloud_platform_eab_kid) > 0 && length(var.google_cloud_platform_eab_hmac_key) > 0
  #   error_message = "enable_google_trust_services_http01 requires google_cloud_platform_eab_kid and google_cloud_platform_eab_hmac_key to be provided"
  # }
}

variable "enable_google_trust_services_dns01" {
  type        = bool
  default     = false
  description = "Enables creating cert-manager DNS01 ClusterIssuers for Google Trust Services. Requires google_cloud_platform_eab_kid and google_cloud_platform_eab_hmac_key to be provided"
  # validation {
  #   condition     = var.enable_google_trust_services && length(var.google_cloud_platform_eab_kid) > 0 && length(var.google_cloud_platform_eab_hmac_key) > 0
  #   error_message = "enable_google_trust_services_dns01 requires google_cloud_platform_eab_kid and google_cloud_platform_eab_hmac_key to be provided"
  # }
}

variable "google_cloud_platform_eab_kid" {
  sensitive   = true
  type        = string
  default     = ""
  description = "Google Trust Services EAB Key ID"
}

variable "google_cloud_platform_eab_hmac_key" {
  sensitive   = true
  type        = string
  default     = ""
  description = "Google Trust Services EAB HMAC Key"
}

variable "google_cloud_platform_email" {
  sensitive = true
  type = string
  default = ""
  description = "Email address to use for Google Trust Services"
}

variable "enable_hetzner_cloud_controller_manager" {
  type        = bool
  default     = true
  description = "Enables deploying Hetzner Cloud Controller Manager"
}

variable "enable_hetzner_cloud_controller_manager_routes" {
  type        = bool
  default     = false
  description = "Enable route creation for native routing on IPv4"
}

variable "hetzner_cloud_controller_manager_api_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Hetzner Cloud API token"
}

variable "hetzner_cloud_controller_manager_hcloud_network_id" {
  type        = string
  sensitive   = false
  default     = ""
  description = "Hetzner Cloud VPN ID"
}

variable "enable_metrics_server" {
  type        = bool
  default     = true
  description = "Enables deploying Kubernetes' metrics-server"
}

variable "enable_kubelet_tls_bootstrapping_controller" {
  type        = bool
  default     = true
  description = "Enables deploying Kubelet TLS Bootstrapping controller"
}

variable "enable_local_path_provisioner" {
  type        = bool
  default     = true
  description = "Enables deploying Rancher's local-path-provisioner"
}

variable "enable_gateway_api" {
  type        = bool
  default     = true
  description = "Enables deploying Kubernetes' SIG Networking's Gateway API CRDs and webhook"
}

variable "enable_metallb" {
  type        = bool
  default     = true
  description = "Enables deploying MetalLB"
}

variable "enable_tetragon" {
  type        = bool
  default     = false
  description = "Enables deploying Cilium's Tetragon"
}

variable "cilium_values" {
  type        = string
  default     = ""
  description = "Cilium values as YAML string"
}

