variable "aws_region" {
  type = string
}

variable "tls_private_key" {
  type = object({
    private_key_openssh = string
    public_key_openssh  = string
  })
}

variable "controller_ips" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "worker_pod_cidrs" {
  type = list(string)
}
