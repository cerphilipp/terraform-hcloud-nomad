#--------------------------------------------------------------------
# Modules
#--------------------------------------------------------------------

module "consul_server" {
  source = "./modules/terraform-hcloud-server"

  providers = {
    hcloud = hcloud
  }

  for_each = local.consul_servers_map

  server_name        = each.value.hostname
  public_ipv4        = local.public_ipv4
  firewall_ids       = [hcloud_firewall.firewall.id]
  ssh_key_ids        = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter         = each.value.datacenter
  subnet_id          = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip         = each.value.private_ip
  server_type        = local.consul_server_type
  cloudinit_packages = local.consul_server_packages
  cloudinit_commands = local.consul_server_commands
  cloudinit_files = [
    {
      path    = "/etc/consul.d/certs/${each.value.certname}-key.pem"
      content = tls_private_key.consul_key[each.key].private_key_pem
    },
    {
      path    = "/etc/consul.d/certs/${each.value.certname}.pem"
      content = tls_locally_signed_cert.consul_cert[each.key].cert_pem,
    },
    {
      path    = "/etc/consul.d/certs/${local.clusters[each.value.cluster_index].consul_datacenter}-${var.consul_domain}-agent-ca.pem"
      content = tls_self_signed_cert.consul_ca.cert_pem
    },
    {
      path    = "/usr/lib/systemd/system/consul.service"
      content = file("${path.module}/templates/consul.service")
    },
    {
      path = "/etc/consul.d/consul.hcl"
      content = templatefile("${path.module}/templates/consul.hcl_server.tpl",
        {
          consul_dc         = local.clusters[each.value.cluster_index].consul_datacenter,
          consul_domain     = var.consul_domain,
          consul_gossip_key = random_id.consul_gossip_encryption_key.b64_std
          index             = each.value.local_index
          consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index]
          private_ip        = each.value.private_ip
      })
    },
    {
      path = "/etc/consul.d/server.hcl"
      content = templatefile("${path.module}/templates/server.hcl_consul.tpl",
        {
          consul_server_count = local.consul_server_count
      })
    }
  ]
}
