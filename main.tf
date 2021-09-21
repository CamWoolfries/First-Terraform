provider "aws" {
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        name = "main-vpc"
    }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
      name = "main-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
      name = "main-igw"
  }
}

resource "aws_route_table" "main_route-table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
    }
    tags = {
        name = "main-route-table"
    }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route-table.id
}

resource "aws_security_group" "main_sg" {
  name        = "allow_ssh-http-tls-8080"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  ingress {
      description = "SSH"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      description = "HTTP"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      description = "TLS"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      description = "8080"
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
      name = "allow_ssh-http-tls-8080"
  }
}

resource "aws_network_interface" "main_nic" {
  subnet_id       = aws_subnet.main_subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.main_sg.id]
  tags = {
      name = "main-nic"
  }
}

resource "aws_eip" "main_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.main_nic.id
  associate_with_private_ip = "10.0.1.10"
  depends_on                = [aws_internet_gateway.main_igw]
  tags = {
      name = "main-eip"
  }
}


resource "aws_instance" "main_server"{
    ami                 = "ami-09e67e426f25ce0d7"
    instance_type       = "t2.micro"
    availability_zone   = "us-east-1a"
    key_name            = var.ec2_ssh_key

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.main_nic.id
    }
    tags = {
        name = "main-server"
    }
}