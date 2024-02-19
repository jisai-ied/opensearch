variable "aws_region" {
  description = "The AWS region to create things in."
  default = "eu-west-1"
}

variable "aws_zone" {
  description = "The AWS available zone"
  default = "eu-west-1a"
}

variable "private_ip" {
  default = "10.0.1.50"
}

variable "cidr_block" {
  default = "0.0.0.0/0"
}

variable "ports" {
  type = map(number)
  default = {
    "ssh" = 22,
    "http" = 80,
    "https" = 443
  }
}