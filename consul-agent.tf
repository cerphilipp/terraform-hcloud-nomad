
#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------

resource "null_resource" "nomad_server_consul_setup" {
  
  for_each = var.consul_server_count > 0 ? local.nomad_servers_map : {}

  triggers = {
    ca_setup = null_resource.consul_ca_setup[each.value.cluster_index].id,
    consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index],
    consul_config = file("${path.module}/templates/consul.hcl_agent.tpl")
  }

  depends_on = [ null_resource.consul_ca_setup ]

  connection {
    host =  module.nomad_server[each.key].public_ip
    private_key = var.ssh_private_key
    user = "root"
    type = "ssh"
    timeout = "10m"
  }

  provisioner "file" {
    destination = "/etc/consul.d/consul.hcl"
    content = templatefile("${path.module}/templates/consul.hcl_agent.tpl", 
    {
      consul_dc = local.clusters[each.value.cluster_index].consul_datacenter,
      consul_domain = var.consul_domain, 
      index = each.value.local_index,
      consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index]      
    })
  }
  
  provisioner "file" {
    destination = local.edit_consul_config_script_path
    content = file("${path.module}/scripts/edit-consul-config.sh")
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.edit_consul_config_script_path}",
      "sed -i -e 's/\r$//' ${local.edit_consul_config_script_path}",
      "${local.edit_consul_config_script_path}",
    ]
  }
}

resource "null_resource" "nomad_client_consul_setup" {
  
  for_each = var.consul_server_count > 0 ? local.nomad_clients_map : {}

  triggers = {
    ca_setup = null_resource.consul_ca_setup[each.value.cluster_index].id,
    consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index],
    consul_config = file("${path.module}/templates/consul.hcl_agent.tpl")
  }

  depends_on = [ null_resource.consul_ca_setup ]

  connection {
    host =  module.nomad_server[each.key].public_ip
    private_key = var.ssh_private_key
    user = "root"
    type = "ssh"
    timeout = "10m"
  }

  provisioner "file" {
    destination = "/etc/consul.d/consul.hcl"
    content = templatefile("${path.module}/templates/consul.hcl_agent.tpl", 
    {
      consul_dc = local.clusters[each.value.cluster_index].consul_datacenter,
      consul_domain = var.consul_domain, 
      index = var.nomad_server_count + each.value.local_index,
      consul_server_ips = local.consul_cluster_server_ips[each.value.cluster_index]          
    })
  }
  
  provisioner "file" {
    destination = local.edit_consul_config_script_path
    content = file("${path.module}/scripts/edit-consul-config.sh")
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.edit_consul_config_script_path}",
      "sed -i -e 's/\r$//' ${local.edit_consul_config_script_path}",
      "${local.edit_consul_config_script_path}",
    ]
  }
}