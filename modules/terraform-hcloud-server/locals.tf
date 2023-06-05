locals {
  os_image        = "centos-stream-8"
  primary_ip_type = var.public_ipv4 ? "ipv4" : "ipv6"

  files = [for f in var.cloudinit_files :
    {
      path        = f.path
      base64      = lookup(f, "base64", true)
      owner       = lookup(f, "owner", null)
      permissions = lookup(f, "permissions", null)
      content     = lookup(f, "base64", true) ? base64encode(f.content) : f.content
  }]

  yum_repos = [
    {
      listname         = "Hashicorp"
      name             = "Hashicorp Stable"
      baseurl          = "https://rpm.releases.hashicorp.com/RHEL/$releasever/$basearch/stable"
      gpgcheck         = "true"
      gpgkey           = "https://rpm.releases.hashicorp.com/gpg"
      enabled_metadata = "true"
    },
    {
      listname         = "Docker CE"
      name             = "Docker CE Stable"
      baseurl          = "https://download.docker.com/linux/centos/$releasever/$basearch/stable"
      gpgcheck         = "true"
      gpgkey           = "https://download.docker.com/linux/centos/gpg"
      enabled_metadata = "true"
    }
  ]

  cloudinit_yml = templatefile("${path.module}/templates/cloudinit.yml.tpl",
    {
      files    = local.files
      repos    = local.yum_repos
      packages = var.cloudinit_packages
      commands = var.cloudinit_commands
  })
}