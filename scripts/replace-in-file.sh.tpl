#!/bin/bash
set -euo pipefail

sed 's/\//\\\//g' ${content_file} > ${content_file}.mod
sed -i -e "s/${replace_regex}/$(cat ${content_file}.mod)/" ${target_file}
rm ${content_file}.mod
