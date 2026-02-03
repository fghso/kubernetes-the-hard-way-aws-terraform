provider "aws" {
  profile = "dev-staging"
  region  = var.aws_region
}

# resource "tls_private_key" "k8s" {
#   algorithm = "RSA"
#   rsa_bits  = "2048"
# }

# module "compute_resources" {
#   source = "./modules/03-compute-resources"

#   aws_region = var.aws_region
#   tls_private_key = {
#     private_key_openssh = tls_private_key.k8s.private_key_openssh
#     public_key_openssh = tls_private_key.k8s.public_key_openssh
#   }
#   controller_ips = var.controller_ips
#   worker_ips = var.worker_ips
#   worker_pod_cidrs = var.worker_pod_cidrs
# }

# module "certificate_authority" {
#   source = "./modules/04-certificate-authority"

#   tls_path = local.tls_path
#   tls_private_key_pem = tls_private_key.k8s.private_key_pem
#   controller_public_ips = module.compute_resources.controller_public_ips
#   controller_hostnames = module.compute_resources.controller_hostnames
#   worker_ips = var.worker_ips
#   worker_public_ips = module.compute_resources.worker_public_ips
#   worker_hostnames = module.compute_resources.worker_hostnames
#   aws_lb_dns_name = module.compute_resources.aws_lb_dns_name
# }

module "kubernetes_configuration_files" {
  source = "./modules/05-kubernetes-configuration-files"

  tls_path = local.tls_path
  kubeconfig_path = abspath("${path.root}/kubeconfig")
  # worker_hostnames = module.compute_resources.worker_hostnames
  worker_hostnames = ["worker-0", "worker-1", "worker-2"]
}
