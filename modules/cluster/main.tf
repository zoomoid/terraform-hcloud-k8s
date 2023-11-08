terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}
