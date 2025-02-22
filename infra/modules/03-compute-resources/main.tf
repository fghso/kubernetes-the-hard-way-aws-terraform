resource "aws_vpc" "k8s" {
 cidr_block = "10.240.0.0/16"

 tags = {
   Name = "k8s-the-hard-way-vpc"
 }
}

resource "aws_subnet" "k8s" {
  vpc_id     = aws_vpc.k8s.id
  cidr_block = "10.240.0.0/24"

  tags = {
    Name = "k8s-the-hard-way-subnet"
  }
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = "k8s-the-hard-way-gw"
  }
}

resource "aws_route_table" "k8s" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s.id
  }

  tags = {
    Name = "k8s-the-hard-way-rt"
  }
}

resource "aws_route_table_association" "k8s" {
  subnet_id      = aws_subnet.k8s.id
  route_table_id = aws_route_table.k8s.id
}

resource "aws_security_group" "k8s" {
  name        = "k8s-the-hard-way-sg"
  description = "Allows internal communication across all protocols and external SSH, ICMP, and HTTPS"
  vpc_id      = aws_vpc.k8s.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.240.0.0/24", "10.200.0.0/16"]
  }

  ingress {
    from_port        = 0
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-the-hard-way-sg"
  }
}

resource "aws_eip" "k8s" {
  domain = "vpc"

  tags = {
    Name = "k8s-the-hard-way-eip"
  }
}

resource "aws_lb" "k8s" {
  name               = "k8s-the-hard-way-lb"
  internal           = false
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id     = aws_subnet.k8s.id
    allocation_id = aws_eip.k8s.id
  }

  tags = {
    Name = "k8s-the-hard-way-lb"
  }
}

resource "aws_lb_target_group" "k8s" {
  name        = "k8s-the-hard-way-tg"
  protocol    = "TCP"
  port        = 6443
  vpc_id      = aws_vpc.k8s.id
  target_type = "ip"
}

resource "aws_lb_target_group_attachment" "k8s" {
  count            = length(var.controller_ips)
  target_group_arn = aws_lb_target_group.k8s.arn
  target_id        = var.controller_ips[count.index]
}

resource "aws_lb_listener" "k8s" {
  load_balancer_arn = aws_lb.k8s.arn
  protocol          = "TCP"
  port              = 6443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s.arn
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-xenial-16.04-amd64-pro-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s-the-hard-way-key-pair"
  public_key = var.tls_private_key.public_key_openssh
}

resource "local_sensitive_file" "k8s" {
  content  = var.tls_private_key.private_key_openssh
  filename = "${path.module}/sshkey-${aws_key_pair.k8s.key_name}"
}

resource "aws_instance" "controller" {
  count                       = length(var.controller_ips)
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  instance_type               = "t2.micro"
  private_ip                  = var.controller_ips[count.index]
  user_data                   = "name=k8s-the-hard-way-controller-${count.index}"
  subnet_id                   = aws_subnet.k8s.id
  source_dest_check           = false

  tags = {
    Name = "k8s-the-hard-way-controller-${count.index}"
  }
}

resource "aws_instance" "worker" {
  count                       = length(var.worker_ips)
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.k8s.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  instance_type               = "t2.micro"
  private_ip                  = var.worker_ips[count.index]
  user_data                   = "name=k8s-the-hard-way-worker-${count.index}|pod-cidr=${var.worker_pod_cidrs[count.index]}"
  subnet_id                   = aws_subnet.k8s.id
  source_dest_check           = false

  tags = {
    Name = "k8s-the-hard-way-worker-${count.index}"
  }
}
