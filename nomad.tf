module "nomad_server" {
  source = "./modules/terraform-hcloud-server"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_servers_map

  server_name        = each.value.hostname
  public_ipv4        = true
  firewall_ids       = [hcloud_firewall.firewall.id]
  ssh_key_ids        = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter         = each.value.datacenter
  subnet_id          = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip         = each.value.private_ip
  server_type        = var.nomad_server_type
  cloudinit_packages = local.nomad_server_packages
  cloudinit_commands = local.nomad_server_commands
  cloudinit_files = concat(local.consul ? [
    {
      path    = "/etc/consul.d/certs/${local.clusters[each.value.cluster_index].consul_datacenter}-${var.consul_domain}-agent-ca.pem"
      content = tls_self_signed_cert.consul_ca.cert_pem
    },
    {
      path = "/etc/consul.d/consul.hcl"
      content = templatefile("${path.module}/templates/consul.hcl_agent.tpl",
        {
          consul_dc         = local.clusters[each.value.cluster_index].consul_datacenter,
          consul_domain     = var.consul_domain,
          consul_gossip_key = random_id.consul_gossip_encryption_key.b64_std
          index             = -1
          consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index]
          private_ip        = each.value.private_ip
      })
    }
    ] : [], var.nomad_first_client_on_server ? [
    {
      path = "/etc/nomad.d/client.hcl"
      content = templatefile("${path.module}/templates/client.hcl.tpl",
        {
          nomad_server_ips = local.nomad_cluster_server_ips[each.value.cluster_index]
      })
    }
    ] : [], [
    {
      path    = "/etc/nomad.d/certs/nomad-agent-ca.pem"
      content = tls_self_signed_cert.nomad_ca.cert_pem
    },
    {
      path    = "/etc/nomad.d/certs/${local.clusters[each.value.cluster_index].nomad_region}-server-nomad.pem"
      content = tls_locally_signed_cert.nomad_cert[each.value.cluster_index].cert_pem
    },
    {
      path    = "/etc/nomad.d/certs/${local.clusters[each.value.cluster_index].nomad_region}-server-nomad-key.pem"
      content = tls_private_key.nomad_key[each.value.cluster_index].private_key_pem
    },
    {
      path = "/etc/nomad.d/nomad.hcl"
      content = templatefile("${path.module}/templates/nomad.hcl.tpl",
        {
          is_server    = true
          region       = local.clusters[each.value.cluster_index].nomad_region
          datacenter   = local.clusters[each.value.cluster_index].nomad_region
          nomad_region = local.clusters[each.value.cluster_index].nomad_region
      })
    },
    {
      path = "/etc/nomad.d/server.hcl"
      content = templatefile("${path.module}/templates/server.hcl.tpl",
        {
          gossip_key       = random_id.nomad_gossip_encryption_key.b64_std
          server_count     = var.nomad_server_count
          nomad_server_ips = local.nomad_cluster_server_ips[each.value.cluster_index]
          private_ip       = each.value.private_ip
      })
    }
  ])
}

module "nomad_client" {
  source = "./modules/terraform-hcloud-server"

  providers = {
    hcloud = hcloud
  }

  for_each = local.nomad_clients_map

  server_name        = each.value.hostname
  public_ipv4        = var.only_public_ipv4_adresses ? true : false
  firewall_ids       = [hcloud_firewall.firewall.id]
  ssh_key_ids        = [hcloud_ssh_key.nomad_server_root_sshkey.id]
  datacenter         = each.value.datacenter
  subnet_id          = hcloud_network_subnet.subnets[each.value.cluster_index].id
  private_ip         = each.value.private_ip
  server_type        = var.nomad_client_type
  cloudinit_packages = local.nomad_client_packages
  cloudinit_commands = local.nomad_client_commands
  cloudinit_files = concat(local.consul ? [
    {
      path    = "/etc/consul.d/certs/${local.clusters[each.value.cluster_index].consul_datacenter}-${var.consul_domain}-agent-ca.pem"
      content = tls_self_signed_cert.consul_ca.cert_pem
    },
    {
      path = "/etc/consul.d/consul.hcl"
      content = templatefile("${path.module}/templates/consul.hcl_agent.tpl",
        {
          consul_dc         = local.clusters[each.value.cluster_index].consul_datacenter,
          consul_domain     = var.consul_domain,
          consul_gossip_key = random_id.consul_gossip_encryption_key.b64_std
          index             = -1
          consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index]
          private_ip        = each.value.private_ip
      })
    }
    ] : [], [
    {
      path    = "/etc/nomad.d/certs/nomad-agent-ca.pem"
      content = tls_self_signed_cert.nomad_ca.cert_pem
    },
    {
      path    = "/etc/nomad.d/certs/${local.clusters[each.value.cluster_index].nomad_region}-server-nomad.pem"
      content = tls_locally_signed_cert.nomad_cert[each.value.cluster_index].cert_pem
    },
    {
      path    = "/etc/nomad.d/certs/${local.clusters[each.value.cluster_index].nomad_region}-server-nomad-key.pem"
      content = tls_private_key.nomad_key[each.value.cluster_index].private_key_pem
    },
    {
      path = "/etc/nomad.d/nomad.hcl"
      content = templatefile("${path.module}/templates/nomad.hcl.tpl",
        {
          is_server    = true
          region       = local.clusters[each.value.cluster_index].nomad_region
          datacenter   = local.clusters[each.value.cluster_index].nomad_region
          nomad_region = local.clusters[each.value.cluster_index].nomad_region
      })
    },
    {
      path = "/etc/nomad.d/client.hcl"
      content = templatefile("${path.module}/templates/client.hcl.tpl",
        {
          nomad_server_ips = local.nomad_cluster_server_ips[each.value.cluster_index]
      })
    }
  ])
}