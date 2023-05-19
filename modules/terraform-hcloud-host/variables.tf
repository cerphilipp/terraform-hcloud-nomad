variable "server_name" {
  type        = string
  description = "Hostname of the server"
}

variable "public_ipv4" {
  type        = bool
  description = "True = primary ipv4 address; False = primary ipv6 address"
}

variable "firewall_ids" {
  type        = list(string)
  description = "List of firewall ids for server"
  default     = []
}

variable "ssh_key_ids" {
  type        = list(string)
  description = "Ssh key ids for server access"
  default     = []
}

variable "datacenter" {
  type        = string
  description = "Datacenter of the server"
}

variable "subnet_id" {
  type        = string
  description = "Subnet id of the server"
}

variable "private_ip" {
  type        = string
  description = "Ip address of the server in the private network"
}

variable "server_type" {
  type        = string
  description = "Cloud server type"
}

variable "labels" {
  type = map(string)
  description = "Labels to apply the server"
  default = {}
}

variable "setup_commands" {
  type        = list(string)
  description = "Setup commands for the server"
  default     = []
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key for ssh access"
  sensitive   = true
}