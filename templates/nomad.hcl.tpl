region = "${region}"
datacenter = "${datacenter}"
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/certs/nomad-agent-ca.pem"
%{if is_server ~}
  cert_file = "/etc/nomad.d/certs/${nomad_region}-server-nomad.pem"
  key_file  = "/etc/nomad.d/certs/${nomad_region}-server-nomad-key.pem"
%{endif ~}

  verify_server_hostname = true
  verify_https_client    = false
}