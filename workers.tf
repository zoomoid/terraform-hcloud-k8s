module "workers" {
  source = "./modules/nodes"

  for_each = local.worker_nodes

  depends_on = [
    module.network,
  ]

  name        = each.key
  server_type = each.value.server_type
  image       = each.value.image
  datacenter  = each.value.datacenter

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

resource "null_resource" "kubeadm_join" {
  for_each = module.workers

  depends_on = [
    module.workers,
    module.dns,
    null_resource.kubeadm_init,
    local_sensitive_file.ca_cert_hash
  ]

  connection {
    type        = "ssh"
    host        = each.value.ipv4_address
    user        = var.ssh_user
    timeout     = "30s"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  # Reboot node once to apply new kernel version.
  # Uses the Node's public IP addresses directly instead of DNS names
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


  # create join configuration
  provisioner "file" {
    content = templatefile("${path.module}/files/join-config.yaml.tftpl", {
      # node_ip             = join(",", [each.value.private_ipv4_address, each.value.ipv6_address])
      node_ip             = each.value.private_ipv4_address,
      api_server_endpoint = local.cluster_endpoint,
      token               = format("%s.%s", random_string.cluster_token_prefix.result, random_string.cluster_token_suffix.result),
      ca_cert_hash        = format("sha256:%s", trimspace(local.ca_cert_hash))
    })
    destination = "/root/config.yaml"
  }

  # kubeadm join
  provisioner "remote-exec" {
    inline = [
      "kubeadm join --config /root/config.yaml"
    ]
  }
}
