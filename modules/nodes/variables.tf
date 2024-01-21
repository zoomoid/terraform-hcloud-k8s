variable "name" {
  type = string
}

variable "server_type" {
  type = string
}

# variable "location" {
#   type    = string
#   default = "fsn1"
# }

variable "datacenter" {
  type    = string
  default = "fsn1-dc14"
}

variable "image" {
  type    = string
  default = "ubuntu-22.04"
}

variable "ssh_keys" {
  type     = list(string)
  nullable = true
}

variable "labels" {
  type    = map(any)
  default = {}
}

variable "ipv4_subnet_id" {
  type = string
}

variable "cloudinit_linux_kernel_package" {
  type = string
  default = "linux-kernel-6.2.0-32-generic"
  description = "Custom kernel to install using apt to support e.g. BBR and more modern networking stuff than the mainline ubuntu LTS kernel does"
}

variable "cloudinit_containerd_url" {
  type = string
  description = "URL from where to download the containerd executables"
}

variable "cloudinit_runc_url" {
  type = string
  description = "URL from where to download the runc executables"
}

variable "cloudinit_containerd_systemd_service_url" {
  type = string
  description = "URL from where to download the containerd systemd service definition"
}

variable "cloudinit_cni_plugins_url" {
  type = string
  description = "URL from where to download the CNI plugins"
}

variable "cloudinit_nerdctl_url" {
  type = string
  description = "URL from where to download the nerdctl executables"
}

variable "cloudinit_kubernetes_apt_keyring" {
  type = string
  description = "URL from where to download the apt keyring for kubernetes' repository"
}

variable "cloudinit_kubernetes_version" {
  type = string
  description = "Kubernetes version to install via apt"
}

variable "ssh_user" {
  description = "SSH user. Required for kernel bootstrapping after cloud init"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "ssh_private_key_file" {
  description = "SSH private key file path. Required for kernel bootstrapping after cloud init"
  type        = string
  sensitive   = true
}
