#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------

resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}

resource "random_id" "consul_ca_id" {
  byte_length = 32
}

resource "tls_self_signed_cert" "consul_ca" {
  private_key_pem = local.cert_ssh_private_key

  validity_period_hours = 43800
  is_ca_certificate     = true

  subject {
    common_name = "Consul Agent CA ${random_id.consul_ca_id.dec}"
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "crl_signing",
  ]
}

resource "tls_private_key" "consul_key" {
  for_each = local.consul_servers_map

  algorithm = "ED25519"
}

resource "tls_cert_request" "consul_csr" {
  for_each = local.consul_servers_map

  private_key_pem = tls_private_key.consul_key[each.key].private_key_pem

  subject {
    common_name = "server.${local.clusters[each.value.cluster_index].consul_datacenter}.${var.consul_domain}"
  }

  dns_names = [
    "server.${local.clusters[each.value.cluster_index].consul_datacenter}.${var.consul_domain}"
  ]
}

resource "tls_locally_signed_cert" "consul_cert" {
  for_each = local.consul_servers_map

  cert_request_pem   = tls_cert_request.consul_csr[each.key].cert_request_pem
  ca_private_key_pem = local.cert_ssh_private_key
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

