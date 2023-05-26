#!/bin/bash
set -euo pipefail

echo "export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem" >> /root/.bashrc

%{ if is_server ~}
echo "export CONSUL_CLIENT_CERT=/etc/consul.d/${consul_datacenter}-server-${consul_domain}-${server_index}.pem" >> /root/.bashrc
echo "export CONSUL_CLIENT_KEY=/etc/consul.d/${consul_datacenter}-server-${consul_domain}-${server_index}-key.pem" >> /root/.bashrc
%{ endif ~}

