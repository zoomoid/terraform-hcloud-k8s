resource "hcloud_firewall" "kubernetes" {
  name = var.name
  dynamic "rule" {
    for_each = local.firewall_rules
    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = lookup(rule.value, "port", null)
      destination_ips = lookup(rule.value, "destination_ips", [])
      source_ips      = lookup(rule.value, "source_ips", [])
    }
  }
}


resource "hcloud_firewall_attachment" "firewall_attachment" {
  firewall_id = hcloud_firewall.kubernetes.id
  server_ids = values(var.nodes)[*].id
}