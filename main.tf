provider "aws" {
  region = "${var.aws_region}"
}

# 1. Create VPC
resource "aws_vpc" "opensrch-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "opensearch-test"
  }
}

# 2. Create Internet Gateway (Enlace a internet)
resource "aws_internet_gateway" "opensrch-gateway" {
    vpc_id = aws_vpc.opensrch-vpc.id  
}

# 3. Create Custom Route Table
resource "aws_route_table" "opensrch-route-table" {
    vpc_id = aws_vpc.opensrch-vpc.id

    route {
        cidr_block = "${"${var.cidr_block}"}"
        gateway_id = aws_internet_gateway.opensrch-gateway.id
    } 

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.opensrch-gateway.id
    }

    tags = {
      Name = "opensearch-route-gateway"
    }
}

# 4. Create a Subnet
resource "aws_subnet" "opensrch-subnet-1" {
    vpc_id = aws_vpc.opensrch-vpc.id

    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.aws_zone}"

    tags = {
      Name = "opensearch-subnet-1"
    }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "opensrch-route-table-association" {
    subnet_id = aws_subnet.opensrch-subnet-1.id
    route_table_id = aws_route_table.opensrch-route-table.id

}

# 6. Create Security Group to allow port 22, 80, 443 (Determina que tipo de comunicacion esta permitida)
resource "aws_security_group" "allow_web_traffic" {
    name = "allow_web_traffic"
    description =  "Allow Web inbound traffic"
    vpc_id = aws_vpc.opensrch-vpc.id

    ingress {
        description = "HTTPS"
        from_port = "${var.ports.https}"
        to_port = "${var.ports.https}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block}"]

    }

    ingress {
        description = "HTTP"
        from_port = "${var.ports.http}"
        to_port = "${var.ports.http}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block}"]

    }

    ingress {
        description = "SSH"
        from_port = "${var.ports.ssh}"
        to_port = "${var.ports.ssh}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block}"]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" # Allow any protocol
        cidr_blocks = ["${var.cidr_block}"]
    }

    tags = {
      Name = "allow_web"
    }
}

# 7. Create Network interface with an IP  in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.opensrch-subnet-1.id
    private_ips = [ "${var.private_ip}" ]
    security_groups = [aws_security_group.allow_web_traffic.id]
}

# 8. Assign an elastic IP to the network interface created in step 7 (Una direccion q AWS enlaza a internet)
resource "aws_eip" "one" {
    # vpc = true -> Deprecated -> Use domain = "vpc" instead
    domain = "vpc"

    # You can specify either instance id or network_interface, but not both
    network_interface = aws_network_interface.web-server-nic.id
    # instance = aws_instance.opensearch.id

    associate_with_private_ip = "${var.private_ip}"
    # EIP may require IGW to exist. set an explicit dependency on the IGW
    depends_on = [ aws_internet_gateway.opensrch-gateway ]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "opensearch" {
  ami           = "${var.aws_ami.ami}"
  instance_type = "${var.aws_ami.instance_type}"
  availability_zone = "${var.aws_zone}"
  key_name = "opensearch-access-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash

                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c "echo 'your very first web server' > /var/www/html/index.html"
                EOF

  tags = {
    Name = "ubuntu-server-opensearch"
  }
}