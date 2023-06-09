#--------------------------------------------------------------------
# data
#--------------------------------------------------------------------
data "hcloud_datacenters" "ds" {
}

#--------------------------------------------------------------------
# locals
#--------------------------------------------------------------------
locals {
  datacenter_location_mapping = { for location in data.hcloud_datacenters.ds.datacenters : location.location.name => location.name }
  network_zone_mapping        = { "fsn1" = "eu-central", "nbg1" = "eu-central", "hel1" = "eu-central", "hil" = "us-west", "ash" = "us-east" }
  consul_server_type_mapping  = { test = "cpx11", small = "cx31", medium = "cx41", large = "cx51" }
  nomad_server_type_mapping   = { test = "cpx11", small = "cx31", medium = "cx41", large = "cx51" }
  nomad_client_type_mapping   = { test = "cpx11", small = "cx31", medium = "cx41", large = "cx51" }
  load_balancer_type_mapping  = { test = "lb11", small = "lb11", medium = "lb21", large = "lb31" }

  cluster_count       = 1
  consul_server_count = var.consul_server_count >= 0 ? var.consul_server_count : 0
  consul_server_type  = lookup(local.consul_server_type_mapping, var.server_size)
  nomad_server_count  = var.nomad_server_count > 0 ? var.nomad_server_count : 1
  nomad_server_type   = lookup(local.nomad_server_type_mapping, var.server_size)
  nomad_client_count  = var.nomad_client_count > 0 ? var.nomad_client_count : 1
  nomad_client_type   = lookup(local.nomad_client_type_mapping, var.server_size)
  load_balancer_type  = lookup(local.load_balancer_type_mapping, var.server_size)

  os_image             = "centos-stream-8"
  network_cidr         = "10.0.0.0/8"
  ssh_private_key      = file(var.ssh_private_key_file)
  cert_ssh_private_key = file(var.cert_ssh_private_key_file)
  consul               = var.consul_server_count > 0
  public_ipv4          = !var.use_ipv6

  #Description of clusters
  cluster_locations = [var.cluster_location]
  cluster_location  = [for i in range(local.cluster_count) : local.cluster_locations[i % length(local.cluster_locations)]]
  cluster_prefix    = [for i in range(local.cluster_count) : "${local.cluster_location[i]}-${floor(i / length(local.cluster_locations))}"]
  cluster_ip_ranges = [for i in range(local.cluster_count) : cidrsubnet(local.network_cidr, 16, i + 1)]

  clients_per_server_count   = var.nomad_first_client_on_server ? local.nomad_client_count - 1 : local.nomad_client_count
  total_nomad_server_count   = local.cluster_count * local.nomad_server_count
  total_nomad_client_count   = var.nomad_first_client_on_server ? (local.total_nomad_server_count - 1) * local.nomad_client_count : local.total_nomad_server_count * local.nomad_client_count
  total_consul_servers_count = local.cluster_count * local.consul_server_count

  subnets = [for i in range(local.cluster_count) :
    {
      index         = i
      cluster_index = i
      ip_range      = cidrsubnet(local.network_cidr, 16, i + 1)
      network_zone  = lookup(local.network_zone_mapping, local.cluster_location[i])
  }]

  clusters = [for i in range(local.cluster_count) :
    {
      index             = i,
      location          = local.cluster_location[i],
      prefix            = local.cluster_prefix[i],
      ip_range          = local.cluster_ip_ranges[i],
      consul_datacenter = local.cluster_prefix[i],
      nomad_region      = local.cluster_prefix[i],
      consul_servers = [for j in range(local.consul_server_count) :
        {
          cluster_index = i,
          local_index   = j,
          hostname      = "${local.cluster_prefix[i]}-consul-server-${j}",
          datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
          private_ip    = cidrhost(local.subnets[i].ip_range, 2 + j),
          certname      = "${local.cluster_prefix[i]}-server-${var.consul_domain}-${j}"
      }]
      servers = [for j in range(local.nomad_server_count) :
        {
          cluster_index = i,
          local_index   = j,
          hostname      = "${local.cluster_prefix[i]}-nomad-server-${j}",
          datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
          private_ip    = cidrhost(local.subnets[i].ip_range, 16 * (j + 1)),
          clients = [for k in range(local.clients_per_server_count) :
            {
              cluster_index = i,
              server_index  = j,
              local_index   = k,
              hostname      = "${local.cluster_prefix[i]}-nomad-server-${j}-client-${k}",
              datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
              private_ip    = cidrhost(local.subnets[i].ip_range, 16 * (j + 1) + k + 1),
          }]
      }]
  }]

  load_balancers_map = var.use_load_balancer ? { for c in local.clusters :
    c.index => {
      name     = "${c.consul_datacenter}-lb"
      location = c.location
    }
  } : {}

  subnets_maps              = { for i in range(local.cluster_count) : i => local.subnets[i] }
  clusters_map              = { for i in range(local.cluster_count) : i => local.clusters[i] }
  nomad_servers             = flatten([for c in local.clusters : c.servers])
  nomad_servers_map         = { for i in range(length(local.nomad_servers)) : i => local.nomad_servers[i] }
  nomad_clients             = flatten([for s in local.nomad_servers : s.clients])
  nomad_clients_map         = { for i in range(length(local.nomad_clients)) : i => local.nomad_clients[i] }
  consul_servers            = flatten([for c in local.clusters : c.consul_servers])
  consul_servers_map        = { for i in range(length(local.consul_servers)) : i => local.consul_servers[i] }
  consul_agents_ips         = concat([for s in local.nomad_servers : s.private_ip], [for c in local.nomad_clients : c.private_ip])
  consul_cluster_server_ips = [for c in local.clusters : "[ ${join(",", [for s in c.consul_servers : "\"${s.private_ip}\""])} ]"]
  nomad_cluster_server_ips  = [for c in local.clusters : "[ ${join(",", [for s in c.servers : "\"${s.private_ip}\""])}]"]

  consul_packages = ["consul"]
  consul_start_commands = [
    "[systemctl, enable, consul]",
    "[systemctl, start, consul]"
  ]
  nomad_packages = ["nomad"]
  nomad_start_commands = [
    "[systemctl, enable, nomad]",
    "[systemctl, start, nomad]"
  ]
  docker_packages = ["docker-ce", "docker-ce-cli", "containerd.io", "docker-buildx-plugin", "docker-compose-plugin"]

  #cloudinit
  consul_server_packages = local.consul_packages
  consul_server_commands = local.consul_start_commands
  nomad_client_packages  = concat(local.consul ? local.consul_packages : [], local.docker_packages, local.nomad_packages)
  nomad_client_commands  = concat(local.consul ? local.consul_start_commands : [], local.nomad_start_commands)
  nomad_server_packages  = concat(local.consul ? local.consul_packages : [], var.nomad_first_client_on_server ? local.docker_packages : [], local.nomad_packages)
  nomad_server_commands  = concat(local.consul ? local.consul_start_commands : [], local.nomad_start_commands)

}