#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------
resource "hcloud_load_balancer" "nomad_server" {
  for_each = local.load_balancers_map

  name               = "${each.value.name}-load-balancer"
  location           = each.value.location
  load_balancer_type = local.load_balancer_type
}

resource "hcloud_load_balancer_network" "nomad_server" {
  for_each = local.load_balancers_map

  load_balancer_id = hcloud_load_balancer.nomad_server[each.key].id
  subnet_id        = hcloud_network_subnet.subnets[each.key].id
}

resource "hcloud_load_balancer_target" "nomad_server" {
  for_each = local.nomad_servers_map

  depends_on       = [module.nomad_server]
  type             = "server"
  server_id        = module.nomad_server[each.key].hcloud_id
  load_balancer_id = hcloud_load_balancer.nomad_server[each.value.cluster_index].id
}

resource "hcloud_load_balancer_service" "nomad_server_ssh" {
  for_each = local.load_balancers_map

  load_balancer_id = hcloud_load_balancer.nomad_server[each.key].id
  protocol         = "tcp"
  destination_port = "4646"
  listen_port      = "4646"
}