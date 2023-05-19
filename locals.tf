#--------------------------------------------------------------------
# data
#--------------------------------------------------------------------
data "hcloud_datacenters" "ds" {
}

#--------------------------------------------------------------------
# locals
#--------------------------------------------------------------------
locals {
  os_image                    = "centos-stream-8"
  datacenter_location_mapping = { for location in data.hcloud_datacenters.ds.datacenters : location.location.name => location.name }
  network_cidr                = "10.0.0.0/8"
  cluster_location            = [for i in range(var.nomad_cluster_count) : var.cluster_locations[i % length(var.cluster_locations)]]
  cluster_prefix              = [for i in range(var.nomad_cluster_count) : "${local.cluster_location[i]}-${floor(i / length(var.cluster_locations))}-"]
  cluster_ip_ranges           = [for i in range(var.nomad_cluster_count) : cidrsubnet(local.network_cidr, 16, i + 1)]

  clients_per_server_count = var.nomad_first_client_on_server ? var.nomad_client_count - 1 : var.nomad_client_count
  total_nomad_server_count = var.nomad_cluster_count * var.nomad_server_count
  total_nomad_client_count = var.nomad_first_client_on_server ? (local.total_nomad_server_count - 1) * var.nomad_client_count : local.total_nomad_server_count * var.nomad_client_count
  total_consul_servers_count = var.nomad_cluster_count * var.consul_server_count

  clusters = [for i in range(var.nomad_cluster_count) :
    {
      index    = i,
      location = local.cluster_location[i],
      prefix   = local.cluster_prefix[i],
      ip_range = local.cluster_ip_ranges[i],
      consul_servers = [ for j in range(var.consul_server_count) :
      {
        cluster_index = i,
        local_index = j,
        hostname   = "${local.cluster_prefix[i]}consul-server-${j}",
        datacenter = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
        private_ip  = cidrhost(hcloud_network_subnet.subnets[i].ip_range, 1 + j),
      }]
      servers = [for j in range(var.nomad_server_count) :
        {
          cluster_index = i,
          local_index   = j,
          hostname      = "${local.cluster_prefix[i]}nomad-server-${j}",
          datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
          private_ip    = cidrhost(hcloud_network_subnet.subnets[i].ip_range, 16 * (j + 1)),
          clients = [for k in range(local.clients_per_server_count) :
            {
              cluster_index = i,
              server_index  = j,
              local_index   = k,
              hostname      = "${local.cluster_prefix[i]}nomad-server-${j}-client-${k}",
              datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
              private_ip    = cidrhost(hcloud_network_subnet.subnets[i].ip_range, 16 * (j + 1) + k + 1),
          }]
      }]
  }]

  clusters_map = { for i in range(var.nomad_cluster_count) : i => local.clusters[i] }
  nomad_servers = flatten([ for c in local.clusters : c.servers])
  nomad_servers_map = { for i in range(length(local.nomad_servers)) : i => local.nomad_servers[i]}
  nomad_clients = flatten([ for s in local.nomad_servers : s.clients])
  nomad_clients_map = { for i in range(length(local.nomad_clients)) : i => local.nomad_clients[i]}
  consul_servers = flatten( [for c in local.clusters : c.consul_servers])
  consul_servers_map = {for i in range(length(local.consul_servers)) : i => local.consul_servers[i]}
  leader_consul_servers_map = var.consul_server_count > 0 ? { for c in local.clusters : c.index => c.consul_servers[0] } : {}

  common_setup_commands = [
    "yum update -y -q",
    "yum install -y -q yum-utils",
    "yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
    "yum -y -q install consul",
    "mkdir --parents /etc/consul.d",
    "touch /etc/consul.d/consul.hcl",
    "chown --recursive consul:consul /etc/consul.d",
    "chmod 640 /etc/consul.d/consul.hcl"
  ]

}