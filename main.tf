# Create a VPC
resource "aws_vpc" "my_main_vpc" {
  cidr_block = var.local_network_cidr

  tags = {
    Name = "my_main_vpc"
  }
}

# Create subnets
resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.my_main_vpc.id
  cidr_block        = var.subnet1_cidr
  availability_zone = "eu-central-1a"

  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.my_main_vpc.id
  cidr_block        = var.subnet2_cidr
  availability_zone = "eu-central-1a"

  tags = {
    Name = "private_subnet1"
  }
}

#internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.my_main_vpc.id
  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.my_main_vpc.id


  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "Public_RT"
  }
}

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.my_main_vpc.id


  tags = {
    Name = "Private_RT"
  }
}

resource "aws_route_table_association" "public_subnet_1a" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "private_subnet_1a" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_RT.id
}

#security groups
resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu_sg"
  description = "Security group for Ubuntu instance with required access"
  vpc_id      = aws_vpc.my_main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ubuntu_icmp" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_vpc_security_group_egress_rule" "ubuntu_icmp_amazon" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  cidr_ipv4         = var.subnet2_cidr
}

resource "aws_vpc_security_group_egress_rule" "ubuntu_http_amazon" {
  security_group_id = aws_security_group.ubuntu_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.subnet2_cidr
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
  ip_protocol       = "-1"
  cidr_ipv4         = var.internet_cidr
}

resource "aws_security_group" "amazon_linux_sg" {
  name        = "amazon_linux_sg"
  description = "Security group for Amazon Linux instance with required access"
  vpc_id      = aws_vpc.my_main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_icmp" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  cidr_ipv4         = var.subnet1_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_ssh" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.subnet1_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_http" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.subnet1_cidr
}

resource "aws_vpc_security_group_ingress_rule" "amazon_linux_https" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.subnet1_cidr
}

resource "aws_vpc_security_group_egress_rule" "amazon_linux_all" {
  security_group_id = aws_security_group.amazon_linux_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.subnet2_cidr
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "ubuntu_instance" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "UbuntuC"
  }

  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]

  user_data = <<-EOF
              #!/bin/bash
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
                tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt update

              apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              docker run hello-world
              EOF
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023.6.*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "amazon_linux_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "AmazonLinuxC"
  }

  subnet_id = aws_subnet.private_subnet1.id
  vpc_security_group_ids = [aws_security_group.amazon_linux_sg.id]
}
