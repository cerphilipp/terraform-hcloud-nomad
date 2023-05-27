#!/bin/bash
set -euo pipefail

chmod 700 ${ssh_private_key_file}
eval $(ssh-agent)
ssh-add ${ssh_private_key_file}
ssh-keyscan -H "127.0.0.1" > /root/.ssh/known_hosts

[[ -d ${dir} ]] && rm -r ${dir}
mkdir ${dir}
cd ${dir}

nomad tls ca create
nomad tls cert create -cli

%{ for cluster in clusters ~}
nomad tls cert create -server -cluster-region ${cluster.nomad_region}
nomad tls cert create -client -cluster-region ${cluster.nomad_region}
%{ for s in cluster.servers ~}
ssh-keyscan -H ${s.private_ip} >> /root/.ssh/known_hosts
scp nomad-agent-ca.pem ${cluster.nomad_region}-server-nomad.pem ${cluster.nomad_region}-server-nomad-key.pem root@${s.private_ip}:/etc/nomad.d/certs
%{ if client_on_server_node ~}
scp ${cluster.nomad_region}-client-nomad.pem ${cluster.nomad_region}-client-nomad-key.pem root@${s.private_ip}:/etc/nomad.d/certs
%{ endif ~}
%{ for c in s.clients ~}
ssh-keyscan -H ${c.private_ip} >> /root/.ssh/known_hosts
scp nomad-agent-ca.pem ${cluster.nomad_region}-client-nomad.pem ${cluster.nomad_region}-client-nomad-key.pem root@${c.private_ip}:/etc/nomad.d/certs
%{ endfor ~}
%{ endfor ~}
%{ endfor ~}