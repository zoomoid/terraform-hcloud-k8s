variable "ssh_host" {
  type        = string
  description = "Hostname of a control plane node to use in the SSH connection"
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "SSH private Key"
  type        = string
  default     = "./.ssh/id_rsa"
}