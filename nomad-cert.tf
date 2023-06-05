#--------------------------------------------------------------------
# RESOURCES
#--------------------------------------------------------------------

resource "random_id" "nomad_gossip_encryption_key" {
  byte_length = 32
}

resource "random_id" "nomad_ca_id" {
  byte_length = 32
}

resource "tls_self_signed_cert" "nomad_ca" {
  private_key_pem = local.cert_ssh_private_key

  validity_period_hours = 43800
  is_ca_certificate     = true

  subject {
    common_name = "Nomad CA ${random_id.consul_ca_id.dec}"
  }

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "crl_signing",
  ]
}

resource "tls_private_key" "nomad_key" {
  for_each = local.clusters_map

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "nomad_csr" {
  for_each = local.clusters_map

  private_key_pem = tls_private_key.nomad_key[each.key].private_key_pem

  subject {
    common_name = "server.${each.value.nomad_region}.nomad"
  }

  dns_names = [
    "server.${each.value.nomad_region}.nomad"
  ]
}

resource "tls_locally_signed_cert" "nomad_cert" {
  for_each = local.clusters_map

  cert_request_pem   = tls_cert_request.nomad_csr[each.key].cert_request_pem
  ca_private_key_pem = local.cert_ssh_private_key
  ca_cert_pem        = tls_self_signed_cert.nomad_ca.cert_pem

  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}