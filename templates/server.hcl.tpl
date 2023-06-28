server {
  enabled = true
  bootstrap_expect = ${server_count}
  encrypt = "${gossip_key}"
  server_join {
    retry_join = ${nomad_server_ips}
  }
}

advertise {
  http = "${private_ip}"
  rpc = "${private_ip}"
  serf = "${private_ip}"
}