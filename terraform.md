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