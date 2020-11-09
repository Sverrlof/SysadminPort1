# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_access_key
}

variable "access_key" {
  type        = string
}

variable "secret_access_key" {
  type        = string
}

# Creates an aws instance
resource "aws_instance" "server-one" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
    tags = {
        Name = "Ubuntuserver One"
    }
  }

/* resource "aws_instance" "server-two" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
}

resource "aws_instance" "server-three" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
} */



