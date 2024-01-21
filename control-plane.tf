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

  ssh_user             = var.ssh_user
  ssh_private_key_file = var.ssh_private_key_file

  ssh_keys = [
    hcloud_ssh_key.default.id
  ]
}

output "control_plane" {
  value = module.control_plane
}

locals {
  kubeadm_init_node = module.control_plane[var.primary_control_plane_node]

  ca_cert_hash = data.remote_file.ca_cert_hash.content
}


resource "null_resource" "kubeadm_init" {
  depends_on = [
    module.control_plane,
    module.dns,
  ]

  # TODO: this is currently wrong! We cannot call kubeadm init on *all* control plane nodes but 
  # rather have to stick to just one! Previous attempts to isolate those cases lead to the commented-out line below
  # which causes terraform to fail due to not knowing all required properties during the "list comprehension"
  # If we explicitly define the type *somehow* marking node_name to be available regardless of the state,
  # this *could* work, but as we currently only deploy one control plane node anyways, the bootstrapping works with the previous
  # node as well

  # for_each = toset([for n in module.control_plane : n if n.name == var.primary_control_plane_node])

  # This is the old version
  for_each = module.control_plane

  connection {
    type        = "ssh"
    host        = local.kubeadm_init_node.ipv4_address
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
      node_ip           = join(",", [each.value.private_ipv4_address, each.value.ipv6_address]),
      certificate_key   = random_bytes.cluster_certificate_key.hex
    })
    destination = "/root/init-config.yaml"
  }

  # kubeadm init/join
  # This is a dirty hack to circumvent the restrictions to for_each sets described above.
  provisioner "remote-exec" {
    inline = [
      each.key == var.primary_control_plane_node ? "kubeadm init --config /root/init-config.yaml" : "echo 'nothing to do, node is not control plane leader, waiting for join stage later'"
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
      "KUBECONFIG=/etc/kubernetes/super-admin.conf kubectl taint node ${var.primary_control_plane_node} node-role.kubernetes.io/control-plane:NoSchedule- || echo 'no taint for control plane found, skipping'"
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

resource "local_sensitive_file" "ca_cert_hash" {
  depends_on = [
    data.remote_file.ca_cert_hash
  ]

  content         = data.remote_file.ca_cert_hash.content
  filename        = "${var.primary_control_plane_node}_kube_apiserver_ca_cert_hash"
  file_permission = "600"
}


resource "null_resource" "kubeadm_join_control_plane" {
  for_each = module.control_plane

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
      certificate_key     = random_bytes.cluster_certificate_key.hex,
      advertise_address   = each.value.ipv4_address,
    })
    destination = "/root/join-config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      each.key == var.primary_control_plane_node ? "echo 'nothing to do, node is control plane leader'" : "kubeadm join --config /root/join-config.yaml"
    ]
  }
}
