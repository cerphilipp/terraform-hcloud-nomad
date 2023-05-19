variable "hcloud_token" {
  type        = string
  description = "hcloud api key"
  sensitive   = true
}

variable "nomad_cluster_count" {
  type        = number
  description = "Number of nomad clusters"
  default     = 1
}

variable "cluster_locations" {
  type        = list(string)
  description = "locations of the clusters"
  default     = ["fsn1", "nbg1", "hel1"]
}

variable "consul_server_count" {
  type = number
  description = "Number of consul servers per cluster"
  default = 1
}   

variable "consul_server_type" {
  type        = string
  description = "Type of servers"
  default     = "cpx11"
}

variable "nomad_server_count" {
  type        = number
  description = "Number of nomad servers per cluster"
  default     = 3
}

variable "nomad_server_type" {
  type        = string
  description = "Type of servers"
  default     = "cpx11"
}

variable "nomad_client_count" {
  type        = number
  description = "Number of nomad clients per server"
  default     = 1
}

variable "nomad_client_type" {
  type        = string
  description = "Type of servers"
  default     = "cpx11"
}

variable "nomad_first_client_on_server" {
  type        = bool
  description = "If true the first nomad client will be installed on the nomad server machine"
  default     = false
}

variable "only_public_ipv4_adresses" {
 type = bool
 description = "If false some servers will use a public ipv6 address, may cause connection issues and break the module" 
 default = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH pubic key for nomad servers"
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key for ssh access"
  sensitive   = true
}