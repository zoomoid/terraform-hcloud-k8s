locals {
  fleet = format("%s.%s", var.dns_fleet, var.dns_root)
  cluster = format("%s.%s", var.dns_cluster, var.dns_root)
}

resource "cloudflare_record" "node_a" {
  for_each = var.nodes

  name    = format("%s.%s", each.value.node_name, local.fleet)
  type    = "A"
  zone_id = var.cloudflare_zone_id

  value =  each.value.ipv4_address
}

resource "cloudflare_record" "node_aaaa" {
  for_each = var.nodes

  
  name    = format("%s.%s", each.value.node_name, local.fleet)
  type    = "AAAA"
  zone_id = var.cloudflare_zone_id
  
  value   = each.value.ipv6_address
}

resource "cloudflare_record" "control_plane_a" {
  for_each = var.control_plane

  name    = format("%s.%s", each.value.node_name, local.cluster)
  type    = "A"
  zone_id = var.cloudflare_zone_id

  value   = each.value.ipv4_address
}

resource "cloudflare_record" "control_plane_aaaa" {
  for_each = var.control_plane

  name    = format("%s.%s", each.value.node_name, local.cluster)
  type    = "AAAA"
  zone_id = var.cloudflare_zone_id

  value   = each.value.ipv6_address
}

#                    -------> control_plane1.cluster...
#                  /
# cluster... ---------------> control_plane2.cluster...
#                  \
#                    -------> control_plane3.cluster...
resource "cloudflare_record" "control_plane_cname" {
  for_each = var.control_plane

  name    = local.cluster
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id

  value   = format("%s.%s", each.value.node_name, local.cluster)
}
