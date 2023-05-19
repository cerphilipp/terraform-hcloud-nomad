#--------------------------------------------------------------------
# locals
#--------------------------------------------------------------------
locals {
  os_image        = "centos-stream-8"
  primary_ip_type = var.public_ipv4 ? "ipv4" : "ipv6"
}