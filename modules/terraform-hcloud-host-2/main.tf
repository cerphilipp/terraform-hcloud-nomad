#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------

resource "hcloud_primary_ip" "public_ip" {
  name          = "${var.server_name}-${local.primary_ip_type}"
  type          = local.primary_ip_type
  assignee_type = "server"
  datacenter    = var.datacenter
  auto_delete   = false
}

resource "hcloud_server" "host" {
  name         = var.server_name
  server_type  = var.server_type
  image        = local.os_image
  datacenter   = var.datacenter
  ssh_keys     = var.ssh_key_ids
  firewall_ids = var.firewall_ids
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.public_ip.id
  }

  connection {
    user        = "root"
    type        = "ssh"
    timeout     = "15m"
    host        = self.ipv6_address
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = var.setup_commands
  }
}


resource "hcloud_server_network" "servernetwork" {
  ip        = var.private_ip
  server_id = hcloud_server.host.id
  subnet_id = var.subnet_id
}
