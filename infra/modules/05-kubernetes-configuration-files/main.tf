resource "terraform_data" "kubeconfig_worker" {
  count = length(var.worker_hostnames)

  provisioner "local-exec" {
    working_dir = "${var.tls_path}/gen"
    command = <<EOF
kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://teste:6443 \
    --kubeconfig=${var.kubeconfig_path}/${var.worker_hostnames[count.index]}.kubeconfig;

kubectl config set-credentials system:node:${var.worker_hostnames[count.index]} \
    --client-certificate=${var.worker_hostnames[count.index]}.pem \
    --client-key=${var.worker_hostnames[count.index]}-key.pem \
    --embed-certs=true \
    --kubeconfig=${var.kubeconfig_path}/${var.worker_hostnames[count.index]}.kubeconfig;

kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${var.worker_hostnames[count.index]} \
    --kubeconfig=${var.kubeconfig_path}/${var.worker_hostnames[count.index]}.kubeconfig;

kubectl config use-context default --kubeconfig=${var.kubeconfig_path}/${var.worker_hostnames[count.index]}.kubeconfig;
EOF
  }

  # connection {
  #   type        = "ssh"
  #   user        = "ubuntu"
  #   host        = var.worker_public_ips[count.index]
  #   private_key = var.tls_private_key_pem
  # }

  # provisioner "file" {
  #   source      = "${var.tls_path}/gen/ca.pem"
  #   destination = "/home/ubuntu/ca.pem"
  # }

  # provisioner "file" {
  #   source      = "${var.tls_path}/gen/worker-${count.index}-key.pem"
  #   destination = "/home/ubuntu/worker-${count.index}-key.pem"
  # }

  # provisioner "file" {
  #   source      = "${var.tls_path}/gen/worker-${count.index}.pem"
  #   destination = "/home/ubuntu/worker-${count.index}.pem"
  # }
}
