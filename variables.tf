variable "aws_region" {
  description = "The AWS region to create things in."
  default     = ""
}

variable "aws_zone" {
  description = "The AWS available zone"
  default     = ""
}

variable "private_ip" {
  default = ""
}

variable "cidr_block" {
  default = ""
}

variable "ports" {
  type = map(number)
  default = {
    "ssh"   = 22
    "http"  = 80
    "https" = 443
  }
}

variable "aws_ami" {
  type = map(string)
  default = {
    "ami"           = ""
    "instance_type" = ""
  }
}
