module "kubeconfig" {
  depends_on = [
    module.control_plane,
    null_resource.kubeadm_init
  ]

  source = "./modules/kubeconfig"

  ssh_host = module.control_plane[var.primary_control_plane_node].ipv4_address

  ssh_user        = var.ssh_user
  ssh_private_key = var.ssh_private_key_file
}
