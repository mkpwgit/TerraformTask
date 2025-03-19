terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
}

variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "local_network_cidr" {
  description = "CIDR block for the local network"
  type        = string
  default     = "10.0.0.0/16"  # Adjust the default value to match your local network
}

resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu_sg"
  description = "Security group for Ubuntu instance with required access"
}

resource "aws_vpc_security_group_ingress_rule" "ubuntu_icmp" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "icmp"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ubuntu_ssh" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ubuntu_http" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ubuntu_https" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_vpc_security_group_egress_rule" "ubuntu_all" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_security_group" "amazon_linux_sg" {
  name        = "amazon_linux_sg"
  description = "Security group for Amazon Linux instance with required access"
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_icmp" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "icmp"
  cidr_ipv4         = var.local_network_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_ssh" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.local_network_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_http" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.local_network_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_https" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.local_network_cidr
}

resource "aws_vpc_security_group_egress_rule" "amazon_linux_all" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = var.local_network_cidr
}

resource "aws_instance" "ubuntu_instance" {
  ami           = "ami-07eef52105e8a2059"
  instance_type = "t2.micro"

  tags = {
    Name = "UbuntuC"
  }

  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              apt update
              apt install -y nginx
              echo "Hello World" >> /var/www/html/index.html
              echo "<br>" >> /var/www/html/index.html
              echo "OS Version: $(lsb_release -a 2>/dev/null | grep 'Description' | cut -f2)" >> /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx

              # Add Docker's official GPG key:
              apt install ca-certificates curl
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc
              
              # Add the repository to Apt sources:
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt update

              apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              docker run hello-world
              EOF
}

resource "aws_instance" "amazon_linux_instance" {
  ami           = "ami-0b74f796d330ab49c"
  instance_type = "t2.micro"

  tags = {
    Name = "AmazonLinuxC"
  }

  vpc_security_group_ids = [aws_security_group.amazon_linux_sg.id]
}
