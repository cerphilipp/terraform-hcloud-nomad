# output "templatefile" {
#   value = templatefile("${path.module}/scripts/setup-consul-cluster.sh.tpl", 
#     { 
#       clusters = local.clusters, 
#       consul_domain = var.consul_domain, 
#       ssh_private_key_file = local.ssh_private_key_copy_path,
#       consul_agents_ips = local.consul_agents_ips
#       dir = local.consul_setup_folder
#     })
# }