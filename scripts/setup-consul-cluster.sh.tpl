#!/bin/bash
set -euo pipefail

chmod 700 ${ssh_private_key_file}
eval $(ssh-agent)
ssh-add ${ssh_private_key_file}
ssh-keyscan -H "127.0.0.1" > /root/.ssh/known_hosts

[[ -d ${dir} ]] && rm -r ${dir}
mkdir ${dir}
cd ${dir}

consul keygen > consul.key
consul tls ca create

%{ for c in clusters ~}
%{ for i in range(length(c.consul_servers)) ~}
consul tls cert create -server -dc ${c.consul_datacenter} -domain ${consul_domain}
ssh-keyscan -H ${c.consul_servers[i].private_ip} >> /root/.ssh/known_hosts
scp consul.key ${consul_domain}-agent-ca.pem ${c.consul_datacenter}-server-${consul_domain}-${i}.pem ${c.consul_datacenter}-server-${consul_domain}-${i}-key.pem root@${c.consul_servers[i].private_ip}:/etc/consul.d/certs
%{ endfor ~}
%{ endfor ~}

%{ for private_ip in consul_agents_ips ~}
ssh-keyscan -H ${private_ip} >> /root/.ssh/known_hosts
scp consul.key ${consul_domain}-agent-ca.pem root@${private_ip}:/etc/consul.d/certs
%{ endfor ~}


