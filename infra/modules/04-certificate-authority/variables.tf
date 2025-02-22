variable "tls_path" {
  type = string
}

variable "tls_private_key_pem" {
  type = string
}

variable "controller_public_ips" {
  type = list(string)
}

variable "controller_hostnames" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "worker_public_ips" {
  type = list(string)
}

variable "worker_hostnames" {
  type = list(string)
}

variable "aws_lb_dns_name" {
  type = string
}
