client {
  enabled = true
  server_join {
    retry_join = ${nomad_server_ips}
  }
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/certs/nomad-agent-ca.pem"
  cert_file = "/etc/nomad.d/certs/${nomad_region}-client-nomad.pem"
  key_file  = "/etc/nomad.d/certs/${nomad_region}-client-nomad-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}