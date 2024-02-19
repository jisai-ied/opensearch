## Terraform

### Authenticated in AWS
```sh
aws sso login
```
### Create terraform file
```sh
touch main.tf
nano main.tf
```

Add provider and simple resource
```terraform
provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "opensearch" {
  ami           = "ami-0905a3c97561e0b69"
  instance_type = "t2.micro"
}
```

```sh
terraform init
terraform plan
```

Apply changes

```terraform
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
```

#### Referencia a resource

```terraform
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
    vpc_id = aws_vpc.firts-vpc.id

    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "dev-subnet"
    }
}

resource "aws_instance" "opensearch" {
  ami           = "ami-0905a3c97561e0b69"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu-server-opensearch"
  }
}
```

#### Terraform files

In this ```.terraform/``` file, terraform installs all the plugins our code needs.

The ```terraform.tfstate``` represents all terraform states. Its to follow the changes.


### Practice Project
1. Create VPC
```sh terraform
resource "aws_vpc" "opensrch-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "opensearch-test"
  }
}
```
2. Create Internet Gateway (Enlace a internet)
```sh terraform
resource "aws_internet_gateway" "opensrch-gateway" {
    vpc_id = aws_vpc.opensrch-vpc.id  
}
```
3. Create Custom Route Table
```sh terraform
resource "aws_route_table" "opensrch-route-table" {
    vpc_id = aws_vpc.opensrch-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
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
```
4. Create a Subnet
```sh terraform
resource "aws_subnet" "opensrch-subnet-1" {
    vpc_id = aws_vpc.opensrch-vpc.id

    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-1a"

    tags = {
      Name = "opensearch-subnet-1"
    }
}
```
5. Associate subnet with Route Table
```sh terraform
resource "aws_route_table_association" "opensrch-route-table-association" {
    subnet_id = aws_subnet.opensrch-subnet-1.id
    route_table_id = aws_route_table.opensrch-route-table.id

}
```
6. Create Security Group to allow port 22, 80, 443 (Determina que tipo de comunicacion esta permitida)
```sh terraform
resource "aws_security_group" "allow_web_traffic" {
    name = "allow_web_traffic"
    description =  "Allow Web inbound traffic"
    vpc_id = aws_vpc.opensrch-vpc.id

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
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
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" # Allow any protocol
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "allow_web"
    }
}
```
7. Create Network interface with an IP  in the subnet that was created in step 4
```sh terraform
resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.opensrch-subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web_traffic.id]
}
```

8. Assign an elastic IP to the network interface created in step 7 (Una direccion q AWS enlaza a internet)
```sh terraform
resource "aws_eip" "one" {
    # vpc = true -> Deprecated -> Use domain = "vpc" instead
    domain = "vpc"

    # You can specify either instance id or network_interface, but not both
    network_interface = aws_network_interface.web-server-nic.id
    # instance = aws_instance.opensearch.id

    associate_with_private_ip = "10.0.1.50"
    # EIP may require IGW to exist. set an explicit dependency on the IGW
    depends_on = [ aws_internet_gateway.opensrch-gateway ]
}
```

9. Create Ubuntu server and install/enable apache2

```sh terraform
resource "aws_instance" "opensearch" {
  ami           = "ami-0905a3c97561e0b69"
  instance_type = "t2.micro"
  availability_zone = "eu-west-1a"
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
´´´