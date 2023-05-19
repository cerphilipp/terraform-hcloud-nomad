module "nomad_server" {
  source = "./modules/terraform-hcloud-host"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_servers_map

  server_name             = each.value.hostname
  public_ipv4             = true
  firewall_ids            = [hcloud_firewall.firewall.id]
  ssh_key_ids             = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter              = each.value.datacenter
  subnet_id               = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip              = each.value.private_ip
  server_type             = var.nomad_server_type
  setup_commands   = local.common_setup_commands
  ssh_private_key         = var.ssh_private_key
}

module "nomad_client" {
  source = "./modules/terraform-hcloud-host"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_clients_map

  server_name             = each.value.hostname
  public_ipv4             = true
  firewall_ids            = [hcloud_firewall.firewall.id]
  ssh_key_ids             = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter              = each.value.datacenter
  subnet_id               = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip              = each.value.private_ip
  server_type             = var.nomad_client_type
  setup_commands   = local.common_setup_commands
  ssh_private_key         = var.ssh_private_key
}
