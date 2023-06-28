variable "hcloud_token" {
  type        = string
  description = "hcloud api key"
  sensitive   = true
}

variable "cluster_location" {
  type        = string
  description = "locations of the cluster, currently possible locations: fsn1, nbg1, hel1,"
  default     = "fsn1"
}

variable "consul_domain" {
  type        = string
  description = "Domain of the consul servers"
  default     = "consul"

  validation {
    condition     = can(regex("^[a-z]+$", var.consul_domain))
    error_message = "consul_domain can only contain lower case letters"
  }
}

variable "server_size" {
  type        = string
  description = "Possible values: test, small, medium, large"
  default     = "small"

  validation {
    condition     = contains(["test", "small", "medium", "large"], var.server_size)
    error_message = "server_size invalid! Possible values: test, small, medium, large"
  }
}

variable "consul_server_count" {
  type        = number
  description = "Number of consul servers, set to 0 if consul should not be used"
  default     = 1

  validation {
    condition     = var.consul_server_count >= 0
    error_message = "consul_server_count must at least have the value 0"
  }
}

variable "nomad_server_count" {
  type        = number
  description = "Number of nomad servers"
  default     = 3

  validation {
    condition     = var.nomad_server_count > 0
    error_message = "nomad_server_count must at least have the value 1"
  }
}

variable "nomad_client_count" {
  type        = number
  description = "Number of nomad clients per server"
  default     = 1

  validation {
    condition     = var.nomad_client_count > 0
    error_message = "nomad_client_count must at least have the value 1"
  }
}

variable "nomad_first_client_on_server" {
  type        = bool
  description = "If true the first nomad client will be installed on the nomad server machine"
  default     = false
}

variable "use_ipv6" {
  type        = bool
  description = "If false some servers will use a public ipv6 address, may cause connection issues and break the module"
  default     = false
}

variable "ssh_public_key" {
  type        = string
  description = "SSH pubic key for nomad servers"
}

variable "ssh_private_key_file" {
  type        = string
  description = "File with SSH private key"
  sensitive   = true
}

variable "cert_ssh_private_key_file" {
  type        = string
  description = "SSH private key file to sign the certificates"
  sensitive   = true
}

variable "use_load_balancer" {
  type        = bool
  description = "Use a loadbalance to balance loads across nomad servers"
  default     = true
}