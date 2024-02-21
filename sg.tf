resource "aws_security_group" "opensearch_security_group" {
  name        = "${var.domain}-sg"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id
  description = "Allow inbound HTTP traffic"

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = [
      var.cidr_block,
    ]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = [
      var.cidr_block,
    ]
  }
}