resource "kubernetes_service_v1" "tbctrl_metrics_service" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-metrics"

    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  spec {
    port {
      name        = "https"
      port        = 8443
      protocol    = "TCP"
      target_port = "https"
    }

    selector = {
      "app.kubernetes.io/name" : "tbctrl"
    }
  }
}

resource "kubernetes_deployment_v1" "tbctrl_controller" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name      = "tbctrl-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "tbctrl"
      }
    }

    template {
      metadata {
        annotations = {
          "kubectl.kubernetes.io/default-container" = "controller"
        }
        labels = {
          "app.kubernetes.io/name" = "tbctrl"
        }
      }
      spec {
        host_network = true
        priority_class_name = "system-cluster-critical"
        termination_grace_period_seconds = 10
        node_selector = {}
        service_account_name = "tbctrl-controller"
        security_context {
          run_as_non_root = true
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        dns_policy = "ClusterFirstWithHostNet"
        toleration {
          effect = "NoSchedule"
          operator = "Equal"
          key = "node-role.kubernetes.io/master" # legacy
        }
        toleration {
          effect = "NoSchedule"
          operator = "Equal"
          key = "node-role.kubernetes.io/control-plane"
        }
        toleration {
          effect = "NoSchedule"
          value = "true"
          key = "node.cloudprovider.kubernetes.io/uninitialized"
        }
        toleration {
          effect = "NoSchedule"
          operator = "Exists"
          key = "node.kubernetes.io/not-ready"
        }
        container {
          name  = "controller"
          image = "ghcr.io/zoomoid/tbctrl:0.5.1"
          args = [
            "--health-probe-bind-address=:8081",
            "--metrics-bind-address=127.0.0.1:8080",
            "--leader-elect"
          ]
          image_pull_policy = "IfNotPresent"
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8081
            }
          }
          resources {
            limits = {
              "cpu"    = "500m",
              "memory" = "128Mi"
            }
            requests = {
              "cpu"    = "100m",
              "memory" = "64Mi"
            }
          }
          env {
            name = "K8S_SERVICE_HOST"
            value = var.external_kubernetes_service_host
          }
          env {
            name = "K8S_SERVICE_PORT"
            value = var.external_kubernetes_service_port
          }
          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 65532
          }
        }
        container {
          name  = "kube-rbac-proxy"
          image = "gcr.io/kubebuilder/kube-rbac-proxy:v0.13.0"
          args = [
            "--secure-listen-address=0.0.0.0:8443",
            "--upstream=http://127.0.0.1:8080/",
            "--logtostderr=true",
            "--v=0"
          ]
          port {
            container_port = 8443
            name           = "https"
            protocol       = "TCP"
          }
          resources {
            limits = {
              "cpu"    = "500m"
              "memory" = "128Mi"
            }
            requests = {
              "cpu"    = "5m"
              "memory" = "64Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account_v1" "tbctrl_controller" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-controller"

    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }
}

resource "kubernetes_role_v1" "tbctrl_leader_election" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-leader-election"

    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
}

resource "kubernetes_cluster_role_v1" "tbctrl_manager" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-manager"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests/approval"]
    verbs      = ["update"]
  }

  rule {
    api_groups     = ["certificates.k8s.io"]
    resource_names = ["kubernetes.io/kubelet-serving"]
    resources      = ["signers"]
    verbs          = ["approve"]
  }
}

resource "kubernetes_cluster_role_v1" "tbctrl_metrics_reader" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-metrics-reader"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_v1" "tbctrl_proxy" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-proxy"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }

  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding_v1" "tbctrl_leader_election" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-leader-election"

    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "tbctrl-leader-election"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tbctrl-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "tbctrl_manager" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-manager"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "tbctrl-manager"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tbctrl-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "tbctrl_proxy" {
  count = var.enable_kubelet_tls_bootstrapping_controller ? 1 : 0

  metadata {
    name = "tbctrl-proxy"

    labels = {
      "app.kubernetes.io/name" = "tbctrl"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "tbctrl-proxy"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tbctrl-controller"
    namespace = "kube-system"
  }
}

