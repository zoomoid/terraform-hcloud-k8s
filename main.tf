terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_api_token
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    client_certificate     = module.kubeconfig.client_certificate
    client_key             = module.kubeconfig.client_key
    cluster_ca_certificate = module.kubeconfig.cluster_ca_certificate
  }
}

provider "kubernetes" {
  # config_path = "./kubeconfig.yaml"
  host                   = local.cluster_endpoint
  client_certificate     = module.kubeconfig.client_certificate
  client_key             = module.kubeconfig.client_key
  cluster_ca_certificate = module.kubeconfig.cluster_ca_certificate

}

provider "kubectl" {
  # config_path = "./kubeconfig.yaml"
  host                   = local.cluster_endpoint
  client_certificate     = module.kubeconfig.client_certificate
  client_key             = module.kubeconfig.client_key
  cluster_ca_certificate = module.kubeconfig.cluster_ca_certificate
}

resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = file(var.ssh_public_key_file)
  labels     = {}
}

resource "random_string" "cluster_token_prefix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_string" "cluster_token_suffix" {
  length  = 16
  upper   = false
  special = false
}

resource "random_bytes" "cluster_certificate_key" {
  length = 32
}
