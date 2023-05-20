#!/bin/bash
set -euo pipefail

sed 's/\//\\\//g' /etc/consul.d/certs/consul.key > /etc/consul.d/certs/consul.key.mod
sed -i -e "s/<consul.key>/$(cat /etc/consul.d/certs/consul.key.mod)/" /etc/consul.d/consul.hcl
rm /etc/consul.d/certs/consul.key.mod
