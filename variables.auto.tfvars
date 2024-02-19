aws_region="eu-west-1"
aws_zone="eu-west-1a"
private_ip="10.0.1.50"
cidr_block="0.0.0.0/0"
ports = {
  ssh   = 22,
  http  = 80,
  https = 443
}
aws_ami = {
  ami = "ami-0905a3c97561e0b69",
  instance_type = "t2.micro"
}