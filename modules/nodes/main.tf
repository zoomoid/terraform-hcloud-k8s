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
    content = templatefile("${path.module}/scripts/cloud-config.yaml", {
      linux_kernel_package           = var.cloudinit_linux_kernel_package
      containerd_url                 = var.cloudinit_containerd_url
      containerd_systemd_service_url = var.cloudinit_containerd_systemd_service_url
      runc_url                       = var.cloudinit_runc_url
      cni_plugins_url                = var.cloudinit_cni_plugins_url
      nerdctl_url                    = var.cloudinit_nerdctl_url
      kubernetes_apt_keyring         = var.cloudinit_kubernetes_apt_keyring
      kubernetes_version             = var.cloudinit_kubernetes_version
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

resource "null_resource" "bootstrap_node_kernel" {

  depends_on = [
    hcloud_server.instance
  ]

  # TODO: remove strict usage of IPv4 node addresses to make this more "future-proof"
  # however, this won't work in WSL2 currently due to the lack of IPv6 support so sticking to IPv4 for now...
  connection {
    type        = "ssh"
    host        = hcloud_server.instance.ipv4_address
    user        = var.ssh_user
    timeout     = "30s"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30s",
      "cloud-init status --wait"
    ]
  }

  # Reboot node once to apply new kernel version.
  # Uses the node's public IP address directly
  provisioner "local-exec" {
    command = <<-EOT
      ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no ${var.ssh_user}@${hcloud_server.instance.ipv4_address} '(sleep 2; reboot)&'; sleep 3
      until ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no -o ConnectTimeout=2 ${var.ssh_user}@${hcloud_server.instance.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for ${hcloud_server.instance.ipv4_address} to reboot and become available..."
        sleep 3s
      done
    EOT
  }
}
