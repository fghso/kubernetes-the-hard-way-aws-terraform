resource "terraform_data" "tls_ca" {
  provisioner "local-exec" {
    command = "cfssl gencert -initca ${var.tls_path}/ca-csr.json | cfssljson -bare ${var.tls_path}/gen/ca"
  }
}

resource "terraform_data" "tls_admin" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -profile=kubernetes \
  ${var.tls_path}/admin-csr.json | cfssljson -bare ${var.tls_path}/gen/admin
EOF
  }
}

resource "local_file" "worker_csr" {
  count = length(var.worker_ips)

  content  = templatefile("${var.tls_path}/worker-csr.tpl.json", {instance_hostname = var.worker_hostnames[count.index]})
  filename = "${var.tls_path}/gen/worker-${count.index}-csr.json"
}

resource "terraform_data" "tls_worker" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  count = length(var.worker_ips)

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -hostname=${var.worker_hostnames[count.index]},${var.worker_public_ips[count.index]},${var.worker_ips[count.index]} \
  -profile=kubernetes \
  ${local_file.worker_csr.*.filename[count.index]} | cfssljson -bare ${var.tls_path}/gen/worker-${count.index}
EOF
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.worker_public_ips[count.index]
    private_key = var.tls_private_key_pem
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/ca.pem"
    destination = "/home/ubuntu/ca.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/worker-${count.index}-key.pem"
    destination = "/home/ubuntu/worker-${count.index}-key.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/worker-${count.index}.pem"
    destination = "/home/ubuntu/worker-${count.index}.pem"
  }
}

resource "terraform_data" "tls_controller_manager" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -profile=kubernetes \
  ${var.tls_path}/kube-controller-manager-csr.json | cfssljson -bare ${var.tls_path}/gen/kube-controller-manager
EOF
  }
}

resource "terraform_data" "tls_kube_proxy" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -profile=kubernetes \
  ${var.tls_path}/kube-proxy-csr.json | cfssljson -bare ${var.tls_path}/gen/kube-proxy
EOF
  }
}

resource "terraform_data" "tls_kube_scheduler" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -profile=kubernetes \
  ${var.tls_path}/kube-scheduler-csr.json | cfssljson -bare ${var.tls_path}/gen/kube-scheduler
EOF
  }
}

resource "terraform_data" "tls_kubernetes" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -hostname=10.32.0.1,${join(",", var.controller_public_ips)},${join(",", var.controller_hostnames)},${var.aws_lb_dns_name},127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local \
  -profile=kubernetes \
  ${var.tls_path}/kubernetes-csr.json | cfssljson -bare ${var.tls_path}/gen/kubernetes
EOF
  }
}

resource "terraform_data" "tls_service_account" {
  triggers_replace = {
    tls_ca = terraform_data.tls_ca.id
  }

  provisioner "local-exec" {
    command = <<EOF
cfssl gencert \
  -ca=${var.tls_path}/gen/ca.pem \
  -ca-key=${var.tls_path}/gen/ca-key.pem \
  -config=${var.tls_path}/ca-config.json \
  -profile=kubernetes \
  ${var.tls_path}/service-account-csr.json | cfssljson -bare ${var.tls_path}/gen/service-account
EOF
  }
}

resource "terraform_data" "tls_controller" {
  triggers_replace = {
    tls_ca         = terraform_data.tls_ca.id
    tls_kubernetes = terraform_data.tls_kubernetes.id
  }

  count = length(var.controller_public_ips)

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.controller_public_ips[count.index]
    private_key = var.tls_private_key_pem
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/ca.pem"
    destination = "/home/ubuntu/ca.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/ca-key.pem"
    destination = "/home/ubuntu/ca-key.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/kubernetes-key.pem"
    destination = "/home/ubuntu/kubernetes-key.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/kubernetes.pem"
    destination = "/home/ubuntu/kubernetes.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/service-account-key.pem"
    destination = "/home/ubuntu/service-account-key.pem"
  }

  provisioner "file" {
    source      = "${var.tls_path}/gen/service-account.pem"
    destination = "/home/ubuntu/service-account.pem"
  }
}
