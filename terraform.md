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