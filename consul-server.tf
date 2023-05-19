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
  public_ipv4             = var.only_public_ipv4_adresses ? true : false
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

resource "null_resource" "consul_ca_setup" {

  count = var.consul_server_count > 0 ? 1 : 0

  depends_on = [ module.consul_server, module.nomad_server, module.nomad_client ]

  connection {
    host =  module.consul_server[0].public_ip
    private_key = var.ssh_private_key
    user = "root"
    type = "ssh"
    timeout = "10m"
  }

  provisioner "file" {
    destination = local.ssh_private_key_copy_path
    content = var.ssh_private_key
  }

  provisioner "file" {
    destination = local.setup_consul_leader_script_path
    content = templatefile("${path.module}/scripts/setup-consul-cluster.sh.tpl", 
    { 
      clusters = local.clusters, 
      consul_domain = var.consul_domain, 
      ssh_private_key_file = local.ssh_private_key_copy_path,
      consul_agents_ips = local.consul_agents_ips
      dir = local.consul_setup_folder
    })
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.setup_consul_leader_script_path}",
      "sed -i -e 's/\r$//' ${local.setup_consul_leader_script_path}",
      "${local.setup_consul_leader_script_path}",
    ]
  }
}

resource "null_resource" "consul_server_setup" {
  
  for_each = var.consul_server_count > 0 ? local.consul_servers_map : {}

  depends_on = [ null_resource.consul_ca_setup ]

  connection {
    host =  each.key.public_ip
    private_key = var.ssh_private_key
    user = "root"
    type = "ssh"
    timeout = "10m"
  }
}