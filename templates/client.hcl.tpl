client {
  enabled = true
  server_join {
    retry_join = ${nomad_server_ips}
  }
}