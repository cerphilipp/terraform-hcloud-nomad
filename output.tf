output "cluster_structure" {
  description = "Internal object used for provisioning the resources"
  value       = local.clusters[0]
}

output "nomad_load_balancer_ipv4" {
  description = "Public IPv4-address of the nomad server loadbalancer"
  value       = var.use_load_balancer ? hcloud_load_balancer.nomad_server[0].ipv4 : ""
}

output "nomad_load_balancer_ipv6" {
  description = "Public IPv6-address of the nomad server loadbalancer"
  value       = var.use_load_balancer ? hcloud_load_balancer.nomad_server[0].ipv6 : ""
}

output "consul_server_public_ip" {
  description = "Public IP-addresses of the consul servers"
  value       = [for k, v in local.consul_servers_map : module.consul_server[k].public_ip]
}

output "nomad_server_public_ip" {
  description = "Public IP-addresses of the first nomad servers"
  value       = [for k, v in local.nomad_servers_map : module.nomad_server[k].public_ip]
}

output "nomad_client_public_ip" {
  description = "Public IP-addresses of the first nomad clients"
  value       = [for k, v in local.nomad_clients_map : module.nomad_client[k].public_ip]
}