terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.2"
    }
  }
}

data "remote_file" "kubeconfig" {
  conn {
    host        = var.ssh_host
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  path = "/root/.kube/config"
}

locals {
  kubeconfig_yaml        = data.remote_file.kubeconfig.content
  kubeconfig_hcl         = yamldecode(local.kubeconfig_yaml)
  cluster_endpoint       = local.kubeconfig_hcl["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(local.kubeconfig_hcl["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig_hcl["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig_hcl["users"][0]["user"]["client-key-data"])
}

# Used for prototyping and testing to immediately write file to disk
# These days, we use outputs for this.
#
# resource "local_file" "kubeconfig" {
#   content         = local.kubeconfig_external
#   filename        = "kubeconfig.yaml"
#   file_permission = "600"
# }
