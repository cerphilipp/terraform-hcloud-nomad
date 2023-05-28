resource "null_resource" "nomad_client_setup" {

  for_each = local.nomad_clients_map

  triggers = {
    nomad_ca_setup = null_resource.nomad_ca_setup.id,
    nomad_config   = file("${path.module}/templates/nomad.hcl.tpl")
    client_config  = file("${path.module}/templates/client.hcl.tpl")
  }

  depends_on = [null_resource.nomad_ca_setup]

  connection {
    host        = module.nomad_client[each.key].public_ip
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
    destination = "/etc/nomad.d/client.hcl"
    content = templatefile("${path.module}/templates/client.hcl.tpl",
      {
        nomad_server_ips = local.nomad_cluster_server_ips[each.value.cluster_index]
        nomad_region     = local.clusters[each.value.cluster_index].nomad_region
    })
  }
}

resource "null_resource" "nomad_client_start" {

  for_each = local.nomad_clients_map

  triggers = {
    nomad_client_setup = null_resource.nomad_client_setup[each.key].id,
  }

  depends_on = [null_resource.nomad_client_setup, null_resource.nomad_server_setup]

  connection {
    host        = module.nomad_client[each.key].public_ip
    private_key = var.ssh_private_key
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = local.nomad_start_commands
  }
}