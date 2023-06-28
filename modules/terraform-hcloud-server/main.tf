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
  user_data    = data.cloudinit_config.cloudinit_config.rendered

  public_net {
    ipv4_enabled = var.public_ipv4
    ipv6_enabled = !var.public_ipv4
    ipv4         = var.public_ipv4 ? hcloud_primary_ip.public_ip.id : null
    ipv6         = var.public_ipv4 ? null : hcloud_primary_ip.public_ip.id
  }

}

data "cloudinit_config" "cloudinit_config" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = local.cloudinit_yml
  }
}

resource "hcloud_server_network" "servernetwork" {
  ip        = var.private_ip
  server_id = hcloud_server.host.id
  subnet_id = var.subnet_id
}