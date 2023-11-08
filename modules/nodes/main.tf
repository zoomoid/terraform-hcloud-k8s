terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

data "cloudinit_config" "name" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/scripts/cloud-config.yaml", {
      linux_kernel_package = var.cloudinit_linux_kernel_package
      containerd_url = var.cloudinit_containerd_url
      containerd_systemd_service_url = var.cloudinit_containerd_systemd_service_url
      runc_url = var.cloudinit_runc_url
      cni_plugins_url = var.cloudinit_cni_plugins_url
      nerdctl_url = var.cloudinit_nerdctl_url
      kubernetes_apt_keyring = var.cloudinit_kubernetes_apt_keyring
      kubernetes_version = var.cloudinit_kubernetes_version
    })
  }
}

resource "hcloud_primary_ip" "node_ipv4" {
  name          = "${var.name}_v4"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
  datacenter    = var.datacenter
}

resource "hcloud_primary_ip" "node_ipv6" {
  name          = "${var.name}_v6"
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = true
  datacenter    = var.datacenter
}

resource "hcloud_server" "instance" {
  name        = var.name
  ssh_keys    = var.ssh_keys
  image       = var.image
  datacenter  = var.datacenter
  server_type = var.server_type

  labels = var.labels

  public_net {
    ipv4 = hcloud_primary_ip.node_ipv4.id
    ipv6 = hcloud_primary_ip.node_ipv6.id
  }

  user_data = data.cloudinit_config.name.rendered
}

resource "hcloud_server_network" "instance_network" {
  subnet_id = var.ipv4_subnet_id
  server_id = hcloud_server.instance.id
}
