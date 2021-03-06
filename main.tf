# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_access_key
}
# Variable to get access key.
# Access key is a variable in a tfvars file
variable "access_key" {
  type        = string
}

# Variable to get secret access key.
# Access key is a variable in a tfvars file
variable "secret_access_key" {
  type        = string
}

# Virtual private cloud
resource "aws_vpc" "product-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "Prod"
  }
}

# AWS internet gateway
# Resource to create a VPC Internet Gateway.
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.product-vpc.id
}

# Creating a custom route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.product-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.product-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "prod-subnet"
  }
}

# Route table association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# AWS security group
# Adds HTTPS, HTTP and SSH
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.product-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# Assign an elastic ip
# Elastic IP address is a static ipv4 address for cloud computing. 
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# Creates an aws instance
/* resource "aws_instance" "server-one" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id 
  }

  # Commands to get apache
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemct1 start apache2
              sudo bash -c 'echo Kjell Inge > /var/www/html/index.html'
              EOF

    tags = {
        Name = "Server one"
    }
  } */

resource "aws_ecs_task_definition" "service" {
  family = "servers"
  container_definitions = file("servers.json")
}

# DEFINING NUMBER OF SERVERS
resource "aws_ecs_service" "ecs-service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.my-first-cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 3  
} 

# SETTING UP CLUSTER
resource "aws_ecs_cluster" "my-first-cluster" {
  name = "first-ever-cluster"
}


