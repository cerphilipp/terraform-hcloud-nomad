#--------------------------------------------------------------------
# Modules
#--------------------------------------------------------------------

module "consul_server" {
  source = "./modules/terraform-hcloud-host"

  providers = {
    hcloud = hcloud
  }

  for_each = local.consul_servers_map

  server_name             = each.value.hostname
  public_ipv4             = false
  firewall_ids            = [hcloud_firewall.firewall.id]
  ssh_key_ids             = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter              = each.value.datacenter
  subnet_id               = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip              = each.value.private_ip
  server_type             = var.consul_server_type
  setup_commands   = local.common_setup_commands
  ssh_private_key         = var.ssh_private_key
}

#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------

#ToDo
# resource "null_resource" "consul_server_setup" {

#   for_each = local.consul_leader_servers_map

#   depends_on = [ module.consul_server, module.nomad_server, module.nomad_client ]

#   connection {
#     host =  module.consul_server.public_ip
#     private_key = var.ssh_private_key
#     user = "root"
#     type = "ssh"
#     timeout = "10m"
#   }

#   provisioner "file" {
#     destination = "/root/.ssh/ssh2.key"
#     content = var.ssh_private_key
#   }
# }