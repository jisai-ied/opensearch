## Terraform

Based on this [freeCodeCamp](https://www.youtube.com/watch?v=SLB_c_ayRMo) tutorial
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
```hcl
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

```hcl
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

```hcl
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

The ```hcl.tfstate``` represents all terraform states. Its to follow the changes.


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
```
## Deploy Amazon Opensearch Service Serverless

[Reference](https://aws.amazon.com/es/blogs/big-data/deploy-amazon-opensearch-serverless-with-terraform/#:~:text=To%20create%20and%20deploy%20an%20OpenSearch%20Serverless%20collection,a%20data%20access%20policy.%207%20Deploy%20using%20Terraform.)

markdown

# Terraform Configuration for Amazon OpenSearch Service Serverless

This Terraform code is used to configure and deploy resources related to Amazon OpenSearch Service Serverless (previously known as Amazon Elasticsearch Service Serverless) using the AWS provider.

### Terraform Version Requirement

```hcl
terraform {
  required_version = ">= 0.12"
}
```

Sets the minimum required version of Terraform for the code.

### AWS Provider Configuration
```hcl
provider "aws" {
  region = var.aws_region
}
```

Configures the AWS provider, specifying the region from a variable called aws_region.

Encryption Security Policy Resource
```hcl
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "encryption-policy"
  type        = "encryption"
  description = "encryption policy for ${var.collection_name}"
  policy      = jsondecode({
    Rules = [
        {
            Resource      = [ "collection/${var.collection_name}" ],
            ResourceType  = "collection"
        }
    ],
    AWSOwnedKey = true
  })
}
```

Creates a security policy for encryption in OpenSearch Serverless, applying it to a specific collection.

### Network Security Policy Resource
```hcl
resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "network-policy"
  type        = "network"
  description = "public access for dashboard, VPC access for collection endpoint"
  policy      = jsondecode([
    {
        Description      = "VPC access for collection endpoint",
        Rules            = [ { ResourceType = "collection", Resource = [ "collection/${var.collection_name}" ] } ],
        AllowFromPublic  = false,
        SourceVPCEs      = [ aws_opensearchserverless_vpc_endpoint.vpc_endpoint.id ]
    },
    {
        Description      = "Public access for dashboards",
        Rules            = [ { ResourceType = "dashboard", Resource = [ "collection/${var.collection_name}" ] } ],
        AllowFromPublic  = true
    }
  ])
}
```
Creates a network security policy for OpenSearch Serverless, allowing public access to dashboards and VPC access to a specific collection endpoint.

### VPC Endpoint Resource
```hcl
resource "aws_opensearchserverless_vpc_endpoint" "vpc_endpoint" {
  name               = "vpc-endpoint"
  vpc_id             = aws_vpc.vpc.id
  subnet_ids         = [ aws_subnet.subnet.id ]
  security_group_ids = [ aws_security_group.security_group.id ]
}
```
Creates a VPC endpoint for OpenSearch Serverless, allowing instances in the VPC to access the OpenSearch service.

### Get Current AWS Account ID Data Block
```hcl
data "aws_caller_identity" "c```hclurrent" {}
```
Fetches information about the current caller's AWS identity, specifically the AWS account ID.

Data Access Policy Resource
```hcl
resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "data-access-policy"
  type        = "data"
  description = "allow index and collection access"
  policy      = jsondecode([
    {
        Rules = [
            {
                ResourceType = "index",
                Resource     = [ "index/${var.collection_name}/*" ],
                Permission   = [ "aoss:*" ]
            },
            {
                ResourceType = "collection",
                Resource     = [ "collection/${var.collection_name}" ],
                Permission   = [ "aoss:*" ]
            }
        ],
        Principal = [ data.aws_caller_identity.current.arn ]
    }
  ])
}
```
Creates a data access policy for OpenSearch Serverless, allowing access to specific indices and collections.

#### Summary
This Terraform code sets up security policies, access policies, and VPC endpoints for Amazon OpenSearch Service Serverless in AWS, with configurations specific to the provided variables.

#### Terraform Version Requirement:
Specifies the minimum required version of Terraform for compatibility with the code.

#### AWS Provider Configuration:
Configures the AWS provider with the specified region obtained from the aws_region variable.

#### Encryption Security Policy Resource:
Creates a security policy for encryption in Amazon OpenSearch Service Serverless, applied to a specific collection. This is essential for securing sensitive data.

#### Network Security Policy Resource:
Defines a network security policy for OpenSearch Serverless. It allows public access to dashboards and VPC access to a specific collection endpoint, ensuring controlled network access.

#### VPC Endpoint Resource:
Creates a VPC endpoint for OpenSearch Serverless, enabling instances within the VPC to communicate with the OpenSearch service privately.

#### Get Current AWS Account ID Data Block:
Retrieves information about the current AWS account ID. This data is used in the data access policy to specify the principal.

#### Data Access Policy Resource:
Establishes a data access policy for OpenSearch Serverless, permitting access to specific indices and collections. The principal is set based on the AWS account ID obtained from the data block.


## AOSS Deployment with Cloudicity

### Terraform Configuration
In the case of Cloudicity, the environment can have two values, `dev` or `prod`.
```hcl
terraform {
  required_version = ">= 0.12"

  backend "s3" {
        bucket = "cloudicity-<enviroment>-tfstates"
        region = "eu-west-1"
        dynamodb_table = "terraform-lock"
        encrypt = true
        key = "<s3_folder>/terraform.tfstate"
  }
}
```
For the S3 folder, it should be created in the same bucket specified in the backend configuration. This can be done either from the AWS console or using the AWS CLI with the following expression:

```sh
aws s3api put-object --bucket cloudicity-<enviroment>-tfstates --key s3_folder/
```

### Remote Backend Configuration
The remote backend refers to the location where Terraform stores and retrieves the state of the managed infrastructure.

```hcl
data "terraform_remote_state" "cloudicity_core" {
    backend = "s3"

    config = {
        bucket = "cloudicity-${var.environment}-tfstates"
        region = var.aws_region
        key = "infra-core/terraform.tfstate"
    }  
}
```

- With `data "terraform_remote_state"`, the type of resource being configured is indicated.
- `"cloudicity_core"` specifies the name for this resource.
- `backend = "s3"` specifies the use of Amazon Simple Storage Service (S3).
- Within `config`, the configuration for the S3 backend is specified.
- The `bucket` indicates the name of the S3 bucket where the Terraform state will be stored.
- The `key` is the path within the bucket where the Terraform state will be stored.

This code block sets up the configuration to use a remote backend in S3 for storing the Terraform state. This approach is useful when working in distributed teams or environments, as it allows sharing and collaborating on the infrastructure state in a centralized manner.

For more information on outputs, refer to [Cloudicity Core Outputs](https://github.com/IED-Electronics/cloudicity-core/blob/0633b0edb30ffa614e811ef7007254dddc957a16/terraform/outputs.tfterraform/outputs.tf).

#### Security Group
For testing purposes, a security group resource has been created locally. In this example, we can see how the remote resource is utilized to obtain the `vpc_id`.

```hcl
# Create Segurity Group
resource "aws_security_group" "opensearch" {
  name        = "opensearch"
  description = "Security Group for Opensearch deployment"
  vpc_id      = data.terraform_remote_state.cloudicity_core.outputs.vpc_id
}
```


### Organization

```
|-- .terraform/
|-- backend/
|   |-- dev.hcl
|-- tfvars/
|   |-- dev.tfvars
|-- main.tf
|-- outputs.tf
|-- providers.tf
|-- sg.tf
|-- variables.tf
```

# Amazon Opensearch Service
[Create a domains](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/createupdatedomains.html)

Para desbloquear el almacenamiento remoto
```sh
terraform force-unlock ID

```

Luego para actualizar en remoto
```sh
terraform init -upgrade
```