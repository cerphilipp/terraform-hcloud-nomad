#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------
resource "hcloud_network" "network" {
  name     = "network-nomad"
  ip_range = local.network_cidr
}

resource "hcloud_network_subnet" "subnets" {
  for_each     = local.subnets_maps
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = each.value.network_zone
  ip_range     = each.value.ip_range
}

resource "hcloud_firewall" "firewall" {
  name = "firewall"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "4646"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_ssh_key" "nomad_server_root_sshkey" {
  name       = "terraform-nomad-ssh-key"
  public_key = var.ssh_public_key
}