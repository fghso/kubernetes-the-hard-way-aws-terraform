output "controller_public_ips" {
  value = aws_instance.controller.*.public_ip
}

output "controller_hostnames" {
  value = split(",", replace(join(",", aws_instance.controller.*.private_dns), ".${var.aws_region}.compute.internal", ""))
}

output "worker_public_ips" {
  value = aws_instance.worker.*.public_ip
}

output "worker_hostnames" {
  value = split(",", replace(join(",", aws_instance.worker.*.private_dns), ".${var.aws_region}.compute.internal", ""))
}

output "aws_lb_dns_name" {
  value = aws_lb.k8s.dns_name
}
