resource "kubernetes_service_account_v1" "hcloud_cloud_controller_manager" {
  count = var.enable_hetzner_cloud_controller_manager ? 1 : 0

  metadata {
    name      = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
    }
  }
  # automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding_v1" "system_cloud_controller_manager" {
  count = var.enable_hetzner_cloud_controller_manager ? 1 : 0

  metadata {
    name = "system:hcloud-cloud-controller-manager"
    labels = {
      "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret_v1" "hcloud_api" {
  count = var.enable_hetzner_cloud_controller_manager ? 1 : 0

  metadata {
    name      = "hcloud"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
    }
  }
  data = {
    token = trimspace(var.hetzner_cloud_controller_manager_api_token)
    network = trimspace(var.hetzner_cloud_controller_manager_hcloud_network_id)
  }
}

resource "kubernetes_deployment_v1" "hcloud_cloud_controller_manager" {
  count = var.enable_hetzner_cloud_controller_manager ? 1 : 0

  metadata {
    name      = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
    }
  }
  spec {
    replicas               = 1
    revision_history_limit = 2
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "hcloud-cloud-controller-manager"
        }
      }
      spec {
        service_account_name = "hcloud-cloud-controller-manager"
        priority_class_name  = "system-cluster-critical"
        dns_policy           = "Default"
        toleration {
          # this taint is set by all kubelets running `--cloud-provider=external`
          # so we should tolerate it to schedule the cloud controller manager 
          key    = "node.cloudprovider.kubernetes.io/uninitialized"
          value  = "true"
          effect = "NoSchedule"
        }
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          # cloud controller manages should be able to run on control planes
          key      = "node-role.kubernetes.io/master"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        # toleration {
        #   key    = "node.kubernetes.io/not-ready"
        #   effect = "NoSchedule"
        #   operator = "Equal"
        # }
        host_network = true
        container {
          name  = "hcloud-cloud-controller-manager"
          image = "hetznercloud/hcloud-cloud-controller-manager:v1.18.0"
          command = concat([
            "/bin/hcloud-cloud-controller-manager",
            "--cloud-provider=hcloud",
            "--leader-elect=false",
            "--allow-untagged-cloud",
            "--cluster-cidr=10.244.0.0/16",
            "--webhook-secure-port=0"
          ], var.enable_hetzner_cloud_controller_manager_routes ? [
            "--route-reconciliation-period=30s",
            "--allocate-node-cidrs=true"
          ] : [])
          # resources {
          #   limits = {
          #     "cpu" = "250m"
          #     "memory" = "200Mi"
          #   }
          #   requests = {
          #     "cpu" = "100m"
          #     "memory" = "50Mi"
          #   }
          # }
          env {
            name = "HCLOUD_TOKEN"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key  = "token"
              }
            }
          }
          env {
            name = "HCLOUD_NETWORK"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key = "network"
                optional = true
              }
            }
          }
        }
      }
    }
  }
}
