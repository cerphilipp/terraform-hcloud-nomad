output "hcloud_id" {
  description = "Host hcloud id"
  value       = hcloud_server.host.id
}

output "hostname" {
  description = "Hostname of the created server"
  value       = hcloud_server.host.name
}

output "private_ipv4" {
  description = "Private ip of the host"
  value       = var.private_ip
  depends_on  = [hcloud_server.host]
}

output "public_ip" {
  description = "Public address of the host"
  value       = var.public_ipv4 ? hcloud_server.host.ipv4_address : hcloud_server.host.ipv6_address
}

output "primary_ip_id" {
  description = "Id of the primary ip address"
  value       = hcloud_primary_ip.public_ip.id
}

output "is_ipv4" {
  description = "True if primary ipv4; False if primary ipv6"
  value       = var.public_ipv4
}

output "cloudinit_yml" {
  description = "Applied cloudinit yml"
  value       = local.cloudinit_yml
}