output "nomad_load_balancer_ipv4" {
  description = "Public IPv4-address of the nomad server loadbalancer"
  value       = var.use_load_balancer ? hcloud_load_balancer.nomad_server[0].ipv4 : ""
}

output "nomad_load_balancer_ipv6" {
  description = "Public IPv6-address of the nomad server loadbalancer"
  value       = var.use_load_balancer ? hcloud_load_balancer.nomad_server[0].ipv6 : ""
}

output "consul_server_public_ip" {
  value = var.consul_server_count > 0 ? module.consul_server[0].public_ip : ""
}

output "nomad_server_public_ip" {
  value = module.nomad_server[0].public_ip
}

output "nomad_client_public_ip" {
  value = length(local.nomad_clients) > 0 ? module.nomad_client[0].public_ip : ""
}