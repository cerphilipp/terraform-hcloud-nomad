#cloud-config

write_files:
%{ for f in files ~}
- path: ${f.path}
  %{ if f.base64 ~}encoding: b64%{ endif }
  content: ${f.content}
  %{ if f.owner == null }owner: root:root%{ else ~}owner: ${f.owner}%{ endif }
  %{ if f.append != null ~}append: '${f.append}'%{ endif }
  %{ if f.permissions != null ~}permissions: '${f.permissions}'%{ endif }
%{ endfor ~}

yum_repos:
%{ for r in repos ~}
  ${r.listname}:
    name: ${r.name}
    baseurl: ${r.baseurl}
    gpgcheck: ${r.gpgcheck}
    gpgkey: ${r.gpgkey}
    enabled_metadata: ${r.enabled_metadata}
%{ endfor ~}

packages:
%{ for p in packages ~}
 - ${p}
%{ endfor ~}

runcmd:
%{ for c in commands ~}
 - ${c}
%{ endfor ~}
