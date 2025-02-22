output "controllers_public_ips" {
  value = aws_instance.controller.*.public_ip
}

output "workers_public_ips" {
  value = aws_instance.worker.*.public_ip
}

