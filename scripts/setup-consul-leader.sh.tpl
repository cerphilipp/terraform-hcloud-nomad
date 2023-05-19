#!/bin/bash
set -euo pipefail

consul keygen > consul.key
consul tls ca create
consul tls cert create -server -dc ${consul_dc} -domain ${consul_domain} # ToDo -additional-dnsname=<secondary_consul_server_name>

%{ for private_ip in consul_server_ips ~}
scp consul.key ${consul_domain}-agent-ca.pem ${consul_dc}-server-${consul_domain}-0.pem ${consul_dc}-server-${consul_domain}-0-key.pem -i ${ssh_private_key_file} root@${private_ip}:/etc/consul.d/certs
%{ endfor ~}

%{ for private_ip in consul_agents_ips ~}
scp consul.key ${consul_domain}-agent-ca.pem -i ${ssh_private_key_file} root@${private_ip}:/etc/consul.d/certs
%{ endfor ~}


