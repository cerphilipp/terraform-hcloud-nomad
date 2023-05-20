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
  
#Description of clusters
  cluster_location            = [for i in range(var.nomad_cluster_count) : var.cluster_locations[i % length(var.cluster_locations)]]
  cluster_prefix              = [for i in range(var.nomad_cluster_count) : "${local.cluster_location[i]}-${floor(i / length(var.cluster_locations))}"]
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
      consul_datacenter = local.cluster_prefix[i],
      consul_servers = [ for j in range(var.consul_server_count) :
      {
        cluster_index = i,
        local_index = j,
        hostname   = "${local.cluster_prefix[i]}-consul-server-${j}",
        datacenter = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
        private_ip  = cidrhost(hcloud_network_subnet.subnets[i].ip_range, 1 + j),
      }]
      servers = [for j in range(var.nomad_server_count) :
        {
          cluster_index = i,
          local_index   = j,
          hostname      = "${local.cluster_prefix[i]}-nomad-server-${j}",
          datacenter    = lookup(local.datacenter_location_mapping, local.cluster_location[i]),
          private_ip    = cidrhost(hcloud_network_subnet.subnets[i].ip_range, 16 * (j + 1)),
          clients = [for k in range(local.clients_per_server_count) :
            {
              cluster_index = i,
              server_index  = j,
              local_index   = k,
              hostname      = "${local.cluster_prefix[i]}-nomad-server-${j}-client-${k}",
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
  consul_agents_ips = concat([ for s in local.nomad_servers : s.private_ip ], [ for c in local.nomad_clients : c.private_ip ])
  consul_cluster_server_ips = [ for c in local.clusters :  "[ ${join(",", [for s in c.consul_servers : "\"${s.private_ip}\""])} ]" ]

# File paths
tmp_folder = "/tmp/terraform-hcloud-nomad/"
script_folder = "${local.tmp_folder}scripts"
setup_consul_leader_script_path = "${local.script_folder}setup-consul-cluster.sh"
edit_consul_config_script_path = "${local.script_folder}edit-consul-config.sh"

consul_setup_folder = "${local.tmp_folder}consul-setup"
ssh_private_key_copy_path = "/root/.ssh/terraform-hcloud-nomad.key"

# Trigger strings

#Inline commands
setup_commands = var.consul_server_count > 0 ? concat(local.common_setup_commands, local.common_consul_commands) : local.common_setup_commands

common_setup_commands = [
  "yum install -y -q yum-utils",
  "yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
  "mkdir ${local.tmp_folder}",
  "mkdir ${local.script_folder}",
]

common_consul_commands = [
  "yum -y -q install consul",
  "mkdir --parents /etc/consul.d",
  "touch /etc/consul.d/consul.hcl",
  "chown --recursive consul:consul /etc/consul.d",
  "chmod 640 /etc/consul.d/consul.hcl",
  "mkdir /etc/consul.d/certs",
]

consul_server_commands = [
  "touch /etc/consul.d/server.hcl",
  "chown --recursive consul:consul /etc/consul.d",
  "chmod 640 /etc/consul.d/server.hcl",
]

consul_agents_setup_commands = [
  "sed -i 's/\\//\\\\\\//g' /etc/consul.d/certs/consul.key",
  "sed -i -e \"s/<consul.key>/$(cat /etc/consul.d/certs/consul.key)/\" /etc/consul.d/consul.hcl"
]
}