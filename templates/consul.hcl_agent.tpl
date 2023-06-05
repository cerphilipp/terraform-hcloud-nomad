datacenter = "${consul_dc}"
data_dir = "/opt/consul"
encrypt = "${consul_gossip_key}"
domain = "${consul_domain}"
bind_addr = "${private_ip}"

retry_join = ${consul_server_ips}

tls {
   defaults {
      ca_file = "/etc/consul.d/certs/${consul_dc}-${consul_domain}-agent-ca.pem"

      verify_incoming = true
      verify_outgoing = true
   }
   internal_rpc {
      verify_server_hostname = true
   }
}

auto_encrypt {
  tls = true
}
