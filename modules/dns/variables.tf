variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare DNS Zone ID"
  sensitive   = true
}

variable "dns_root" {
  type        = string
  description = "DNS root for all fleet nodes"
}

variable "dns_fleet" {
  type        = string
  default     = "fleet"
  description = "DNS subdomain for all fleet nodes"
}

variable "dns_cluster" {
  type        = string
  default     = "cluster"
  description = "DNS subdomain for all control plane nodes"
}

variable "nodes" {
  type        = any
  description = "Node to create DNS records for"
}

variable "control_plane" {
  type        = any
  description = "Control plane nodes to create control plane RRs for"
}
