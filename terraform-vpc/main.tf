provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "main_vpc_prod" {  # "name" (hier dürch "main_vpc_prod" ersetz) ist der Interner Terraform Name welcher nicht auf AWS angezeigt wird.
    cidr_block = "10.0.0.0/16" # Die wichtigste Eingabe um ein VPC erstellen zu können (alleine diese reicht aus).
    tags = {
        Name = "main-prod-vpc" # Name vom VPC, welcher auf AWS angzeigt wird.
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id # Verweis auf die zugehörige VPC (ohne ID, einfach mit dem Namen)
    tags = {
        Name = "main-prod-igw" # Name vom IGW, welcher auf AWS angzeigt wird.
  }
}


# Public subnet
resource "aws_subnet" "main_public_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true # Werden automatisch öffentliche IP bekommen.

    tags = {
        Name = "main-prod-public-subnet-a"
  }
}


# Private subnet
resource "aws_subnet" "main_private_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.128.0/20"
    availability_zone = "eu-central-1a"

    tags = {
        Name = "main-prod-private-subnet-a"
  }
}

# Public Route Table 
resource "aws_route_table" "public_rtb_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw_prod.id
    }

    tags = {
        Name = "main-prod-vpc-public-route-table"
    }
}

# Public Subnet to Public Route Table Association
resource "aws_route_table_association" "public_rtb_subnet_assoc_prod" {
    subnet_id = aws_subnet.main_public_subnet_a_prod.id
    route_table_id = aws_route_table.public_rtb_prod.id
}

# Security Group
resource "aws_security_group" "web_sg_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id

    ingress { # Eingehender Datenverkehr
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }  

    egress { # Ausgehender Datenverkehr
      from_port = 0 # Alle zulassen
      to_port = 0 # Alle zulassen
      protocol = "-1" # Alle zulassen
      cidr_blocks = [ "0.0.0.0/0" ]           
    }

    tags = {
        Name = "web-security-group-prod"
    }
}


# EC2 Instance - Web Server
resource "aws_instance" "web_server_prod" {
  ami = "ami-0de02246788e4a354"  
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_public_subnet_a_prod.id  # Direkte ID vom Subnetz ohne VPC ID
  vpc_security_group_ids = [ aws_security_group.web_sg_prod.id ]

user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "Hello World from $(hostname -f)!" > /var/www/html/index.html
                EOF

tags = {
    Name = "web-server-prod"
}
  }


# Outputs

output "instance_public_ip" {
    description = "The Public IP of the EC2 Inctance"
    value = aws_instance.web_server_prod.public_ip
}