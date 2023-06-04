resource "null_resource" "nomad_server_setup" {

  for_each = local.nomad_servers_map

  triggers = {
    nomad_ca_setup = null_resource.nomad_ca_setup.id,
    nomad_config   = file("${path.module}/templates/nomad.hcl.tpl")
    server_config  = file("${path.module}/templates/server.hcl.tpl")
  }

  depends_on = [null_resource.nomad_ca_setup]

  connection {
    host        = module.nomad_server[each.key].public_ip
    private_key = var.ssh_private_key
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
  }

  provisioner "file" {
    destination = "/etc/nomad.d/nomad.hcl"
    content = templatefile("${path.module}/templates/nomad.hcl.tpl",
      {
        region     = local.clusters[each.value.cluster_index].nomad_region
        datacenter = local.clusters[each.value.cluster_index].nomad_region
        private_ip = each.value.private_ip
    })
  }

  provisioner "file" {
    destination = "/etc/nomad.d/server.hcl"
    content = templatefile("${path.module}/templates/server.hcl.tpl",
      {
        server_count     = var.nomad_server_count
        nomad_server_ips = local.nomad_cluster_server_ips[each.value.cluster_index]
        nomad_region     = local.clusters[each.value.cluster_index].nomad_region
        private_ip       = each.value.private_ip
    })
  }

  provisioner "file" {
    destination = local.replace_in_file_script_path
    content = templatefile("${path.module}/scripts/replace-in-file.sh.tpl",
      {
        content_file  = "/etc/nomad.d/certs/gossip.key"
        replace_regex = "<gossip.key>"
        target_file   = "/etc/nomad.d/server.hcl"
    })
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.replace_in_file_script_path}",
      "sed -i -e 's/\r$//' ${local.replace_in_file_script_path}",
      "${local.replace_in_file_script_path}",
    ]
  }
}

resource "null_resource" "nomad_server_start" {

  for_each = local.nomad_servers_map

  triggers = {
    nomad_server_setup = null_resource.nomad_server_setup[each.key].id,
  }

  depends_on = [null_resource.nomad_server_setup]

  connection {
    host        = module.nomad_server[each.key].public_ip
    private_key = var.ssh_private_key
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = local.nomad_start_commands
  }
}