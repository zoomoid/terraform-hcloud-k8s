module "control_plane" {
  source = "./modules/nodes"

  for_each = local.control_plane_nodes

  depends_on = [
    module.network
  ]

  name        = each.key
  server_type = each.value.server_type
  image       = each.value.image
  # location    = each.value.location
  datacenter = each.value.datacenter

  ipv4_subnet_id = module.network.ipv4_subnet_id

  cloudinit_linux_kernel_package           = var.cloudinit_linux_kernel_package
  cloudinit_containerd_url                 = var.cloudinit_containerd_url
  cloudinit_containerd_systemd_service_url = var.cloudinit_containerd_systemd_service_url
  cloudinit_runc_url                       = var.cloudinit_runc_url
  cloudinit_cni_plugins_url                = var.cloudinit_cni_plugins_url
  cloudinit_nerdctl_url                    = var.cloudinit_nerdctl_url
  cloudinit_kubernetes_apt_keyring         = var.cloudinit_kubernetes_apt_keyring
  cloudinit_kubernetes_version             = var.cloudinit_kubernetes_version

  ssh_keys = [
    hcloud_ssh_key.default.id
  ]
}

locals {
  kubeadm_init_node = module.control_plane
}

resource "null_resource" "kubeadm_init" {
  for_each = toset([for n in module.control_plane : n if n.name == var.primary_control_plane_node])

  depends_on = [
    module.control_plane,
    module.dns,
  ]

  connection {
    type        = "ssh"
    host        = each.value.ipv4_address
    user        = var.ssh_user
    timeout     = "30s"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/init-config.yaml.tftpl", {
      control_plane_endpoint = local.cluster_endpoint
      extra_sans = [
        local.cluster_prefix,
        local.fleet_prefix,
        each.value.private_ipv4_address,
        each.value.ipv4_address,
        each.value.ipv6_address,
      ]
      pod_subnet        = "10.244.0.0/16,fd00::244:0:0/56"  # The latter IPv6 cidrs are NOT routable for cilium native routing!
      service_subnet    = "10.96.0.0/16,fd00:0:0:100::/112" # The latter IPv6 cidrs are NOT routable for cilium native routing!
      advertise_address = each.value.ipv4_address
      token             = format("%s.%s", random_string.cluster_token_prefix.result, random_string.cluster_token_suffix.result)
      node_ip           = join(",", [each.value.private_ipv4_address, each.value.ipv6_address])
    })
    destination = "/root/config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  # Reboot node once to apply new kernel version.
  # Uses the node's public IP address directly
  provisioner "local-exec" {
    command = <<-EOT
      ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no ${var.ssh_user}@${each.value.ipv4_address} '(sleep 2; reboot)&'; sleep 3
      until ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no -o ConnectTimeout=2 ${var.ssh_user}@${each.value.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for ${each.value.ipv4_address} to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # kubeadm init/join
  provisioner "remote-exec" {
    inline = [
      each.key == var.primary_control_plane_node ? "kubeadm init --config /root/config.yaml" : "kubeadm join --config /root/config.yaml"
    ]
  }

  # configure kubeconfig on remote
  provisioner "remote-exec" {
    inline = [
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    ]
  }

  # Allow control plane kubelet to schedule pods
  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "kubectl taint node ${var.primary_control_plane_node} node-role.kubernetes.io/control-plane:NoSchedule-"
    ]
  }

  # create CA cert hash for joining new nodes to the cluster
  provisioner "remote-exec" {
    inline = [
      "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > /root/.ca_cert_hash"
    ]
  }
}

# Copy CA cert hash for joining new nodes
data "remote_file" "ca_cert_hash" {
  depends_on = [
    null_resource.kubeadm_init
  ]

  conn {
    host        = module.control_plane[var.primary_control_plane_node].ipv4_address
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  path = "/root/.ca_cert_hash"
}

locals {
  ca_cert_hash = data.remote_file.ca_cert_hash.content
}

resource "local_sensitive_file" "ca_cert_hash" {
  depends_on = [
    data.remote_file.ca_cert_hash
  ]

  content         = data.remote_file.ca_cert_hash.content
  filename        = "${var.primary_control_plane_node}_kube_apiserver_ca_cert_hash"
  file_permission = "600"
}

resource "null_resource" "kubeadm_join_control_plane" {
  for_each = toset([for n in module.control_plane : n if n.name != var.primary_control_plane_node])

  depends_on = [
    module.control_plane,
    module.dns,
    null_resource.kubeadm_init,
    local_sensitive_file.ca_cert_hash,
  ]

  connection {
    type        = "ssh"
    host        = each.value.ipv4_address
    user        = var.ssh_user
    timeout     = "30s"
    private_key = file(var.ssh_private_key_file)
  }

  # create join control plane configuration
  provisioner "file" {
    content = templatefile("${path.module}/files/join-control-plane-config.yaml.tftpl", {
      node_ip             = each.value.private_ipv4_address,
      api_server_endpoint = local.cluster_endpoint,
      token               = format("%s.%s", random_string.cluster_token_prefix.result, random_string.cluster_token_suffix.result),
      ca_cert_hash        = format("sha256:%s", trimspace(local.ca_cert_hash))
      certificate_key     = random_string.cluster_certificate_key.result,
      advertise_address   = each.value.ipv4_address,
    })
    destination = "/root/config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  # Reboot node once to apply new kernel version.
  # Uses the node's public IP address directly
  provisioner "local-exec" {
    command = <<-EOT
      ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no ${var.ssh_user}@${each.value.ipv4_address} '(sleep 2; reboot)&'; sleep 3
      until ssh -i ${var.ssh_private_key_file} -o StrictHostKeyChecking=no -o ConnectTimeout=2 ${var.ssh_user}@${each.value.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for ${each.value.ipv4_address} to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # configure kubeconfig on remote
  provisioner "remote-exec" {
    inline = [
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    ]
  }
}
