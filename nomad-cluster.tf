module "nomad_server" {
  source = "./modules/terraform-hcloud-host"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_servers_map

  server_name     = each.value.hostname
  public_ipv4     = true
  firewall_ids    = [hcloud_firewall.firewall.id]
  ssh_key_ids     = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter      = each.value.datacenter
  subnet_id       = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip      = each.value.private_ip
  server_type     = var.nomad_server_type
  setup_commands  = concat(local.setup_commands, local.common_nomad_commands)
  ssh_private_key = var.ssh_private_key
}

module "nomad_client" {
  source = "./modules/terraform-hcloud-host"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_clients_map

  server_name     = each.value.hostname
  public_ipv4     = var.only_public_ipv4_adresses ? true : false
  firewall_ids    = [hcloud_firewall.firewall.id]
  ssh_key_ids     = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter      = each.value.datacenter
  subnet_id       = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip      = each.value.private_ip
  server_type     = var.nomad_client_type
  setup_commands  = concat(local.setup_commands, local.common_nomad_commands)
  ssh_private_key = var.ssh_private_key
}

resource "null_resource" "nomad_ca_setup" {

  triggers = {
    nomad_server_ids = join(",", [ for s in module.nomad_server : s.hcloud_id ])
    nomad_server_ips = join(",", [ for s in module.nomad_server : s.private_ipv4 ]),
    nomad_client_ids = join(",", [ for c in module.nomad_client : c.hcloud_id ]),
    nomad_client_ips = join(",", [ for c in module.nomad_client : c.private_ipv4 ]),
  }

  depends_on = [ module.nomad_server, module.nomad_client ]

  connection {
    host        = module.nomad_server[0].public_ip
    private_key = var.ssh_private_key
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
  }

  provisioner "file" {
    destination = local.ssh_private_key_copy_path
    content     = var.ssh_private_key
  }

  provisioner "file" {
    destination = local.setup_nomad_ca_script_path
    content = templatefile("${path.module}/scripts/setup-nomad-ca.sh.tpl",
      {
        clusters              = local.clusters
        ssh_private_key_file  = local.ssh_private_key_copy_path
        dir                   = local.nomad_setup_folder
        client_on_server_node = var.nomad_first_client_on_server
    })
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.setup_nomad_ca_script_path}",
      "sed -i -e 's/\r$//' ${local.setup_nomad_ca_script_path}",
      "${local.setup_nomad_ca_script_path}",
      "rm -f ${local.ssh_private_key_copy_path}"
    ]
  }
}