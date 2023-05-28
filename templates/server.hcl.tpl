server {
  enabled = true
  bootstrap_expect = ${server_count}
  encrypt = "<gossip.key>"
  server_join {
    retry_join = ${nomad_server_ips}
  }
}

advertise {
  http = "${private_ip}"
  rpc = "${private_ip}"
  serf = "${private_ip}"
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/certs/nomad-agent-ca.pem"
  cert_file = "/etc/nomad.d/certs/${nomad_region}-server-nomad.pem"
  key_file  = "/etc/nomad.d/certs/${nomad_region}-server-nomad-key.pem"

  verify_server_hostname = true
  verify_https_client    = false
}