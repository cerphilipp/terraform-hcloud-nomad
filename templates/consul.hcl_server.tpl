datacenter = "${consul_dc}"
data_dir = "/opt/consul"
encrypt = "<consul.key>"
domain = "${consul_domain}"

retry_join = ${consul_server_ips}

tls {
   defaults {
      ca_file = "/etc/consul.d/certs/${consul_domain}-agent-ca.pem"
      cert_file = "/etc/consul.d/certs/${consul_dc}-server-${consul_domain}-${index}.pem"
      key_file = "/etc/consul.d/certs/${consul_dc}-server-${consul_domain}-${index}-key.pem"

      verify_incoming = true
      verify_outgoing = true
   }
   internal_rpc {
      verify_server_hostname = true
   }
}

auto_encrypt {
  allow_tls = true
}
