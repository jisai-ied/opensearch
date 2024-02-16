provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "firts-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "dev"
    }
}

resource "aws_subnet" "subnet-1" {
    vpc_id  = aws_vpc.firts-vpc.id

    cidr_block = "10.0.1.0/24"

    tags  = {
      Name  = "dev-subnet"
    }
}

resource "aws_instance" "opensearch" {
  ami  = "ami-0905a3c97561e0b69"
  instance_type = "t2.micro"

  tags = {
    Name  = "ubuntu-server-opensearch"
  }
}