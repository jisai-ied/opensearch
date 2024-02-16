provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "opensearch" {
  ami           = "ami-0905a3c97561e0b69"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu-server-opensearch"
  }
}