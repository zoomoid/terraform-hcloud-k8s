variable "control_plane_nodes" {
  type = map(object({
    server_type = string
    image       = optional(string, "ubuntu-22.04"),
    datacenter  = string
  }))
  description = "Map with key = node_name and containing server_type"
}

variable "worker_nodes" {
  type        = map(object({
    server_type = string
    image       = optional(string, "ubuntu-22.04"),
    datacenter  = string
  }))
  description = "Map with key = node_name and containing server_type"
}

variable "cloudinit_linux_kernel_package" {
  type        = string
  default     = "linux-kernel-6.2.0-32-generic"
  description = "Custom kernel to install using apt to support e.g. BBR and more modern networking stuff than the mainline ubuntu LTS kernel does"
}

variable "cloudinit_containerd_url" {
  type        = string
  description = "URL from where to download the containerd executables"
}

variable "cloudinit_runc_url" {
  type        = string
  description = "URL from where to download the runc executables"
}

variable "cloudinit_containerd_systemd_service_url" {
  type        = string
  description = "URL from where to download the containerd systemd service definition"
}

variable "cloudinit_cni_plugins_url" {
  type        = string
  description = "URL from where to download the CNI plugins"
}

variable "cloudinit_nerdctl_url" {
  type        = string
  description = "URL from where to download the nerdctl executables"
}

variable "cloudinit_kubernetes_apt_keyring" {
  type        = string
  description = "URL from where to download the apt keyring for kubernetes' repository"
}

variable "cloudinit_kubernetes_version" {
  type        = string
  description = "Kubernetes version to install via apt of the form <X.Y.Z>. The mandatory -00 is automatically added"
}

variable "dns_root" {
  type        = string
  description = "Common root for all DNS records for cluster nodes"
  default     = "example.com"
}

variable "dns_cluster_subdomain" {
  type    = string
  default = "cluster"
}

variable "dns_fleet_subdomain" {
  type    = string
  default = "fleet"
}

variable "hcloud_api_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "ssh_public_key_file" {
  description = "SSH public key file path"
  default     = "./.ssh/id_rsa.pub"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_file" {
  description = "SSH private key file path"
  type        = string
  default     = "./.ssh/id_rsa"
  sensitive   = true
}

variable "control_plane_api_server_port" {
  type        = number
  default     = 6443
  description = "Kubernetes API Server port"
}

variable "primary_control_plane_node" {
  type        = string
  description = "Primary control plane node on which to run kubeadm init. Must be a DNS name."
  default     = "control-plane"
}

variable "enable_firewall" {
  type        = bool
  default     = true
  description = "Enable Hetzner Cloud Firewall"
}

variable "static_firewall_rules" {
  type = list(object({
    direction  = string
    protocol   = string
    port       = optional(string)
    source_ips = list(string)
  }))
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

variable "cloudflare_zone_id" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare DNS Zone ID"
}

variable "cloudflare_email" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Email to use for Cloudflare authentication"
}

variable "cloudflare_api_key" {
  sensitive   = true
  type        = string
  default     = ""
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
  type        = string
  default     = "traefik"
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
  sensitive   = true
  type        = string
  default     = ""
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
  description = "Enables route creation for pod routing on the virtual network"
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
