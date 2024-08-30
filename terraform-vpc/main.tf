provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "main_vpc_prod" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "main-prod-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    tags = {
        Name = "main-prod-igw"
  }
}

# Public subnet A (eu-central-1a)
resource "aws_subnet" "main_public_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "main-prod-public-subnet-a"
  }
}

# Public subnet B (eu-central-1b)
resource "aws_subnet" "main_public_subnet_b_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.16.0/20"
    availability_zone = "eu-central-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "main-prod-public-subnet-b"
  }
}

# Private subnet A (eu-central-1a)
resource "aws_subnet" "main_private_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.128.0/20"
    availability_zone = "eu-central-1a"

    tags = {
        Name = "main-prod-private-subnet-a"
  }
}

# Private subnet B (eu-central-1b)
resource "aws_subnet" "main_private_subnet_b_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.144.0/20"
    availability_zone = "eu-central-1b"

    tags = {
        Name = "main-prod-private-subnet-b"
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

# Public Subnet A to Public Route Table Association
resource "aws_route_table_association" "public_rtb_subnet_a_assoc_prod" {
    subnet_id = aws_subnet.main_public_subnet_a_prod.id
    route_table_id = aws_route_table.public_rtb_prod.id
}

# Public Subnet B to Public Route Table Association
resource "aws_route_table_association" "public_rtb_subnet_b_assoc_prod" {
    subnet_id = aws_subnet.main_public_subnet_b_prod.id
    route_table_id = aws_route_table.public_rtb_prod.id
}

# Security Group
resource "aws_security_group" "web_sg_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id

    # HTTP (Port 80) Zugriff
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    } 

    # SSH (Port 22) Zugriff
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # Benutzerdefinierter Port TCP 3000
    ingress {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "web-security-group-prod"
    }
}

# EC2 Instance - Web Server in Public Subnet A
resource "aws_instance" "web_server_a_prod" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_public_subnet_a_prod.id
  vpc_security_group_ids = [aws_security_group.web_sg_prod.id]

  user_data = <<-EOF
                #!/bin/bash

                sudo dnf update -y
                sudo dnf install git -y

                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                nvm install --lts

                git clone https://github.com/gal-projects/notes-app-express.git /home/ec2-user/notes-app-express
                cd /home/ec2-user/notes-app-express 
                npm install
                npm run build
                npm start
                EOF

  tags = {
    Name = "web-server-a-prod"
  }
}

# EC2 Instance - Web Server in Public Subnet B
resource "aws_instance" "web_server_b_prod" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_public_subnet_b_prod.id
  vpc_security_group_ids = [aws_security_group.web_sg_prod.id]

  user_data = <<-EOF
                #!/bin/bash

                sudo dnf update -y
                sudo dnf install git -y

                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                nvm install --lts

                git clone https://github.com/gal-projects/notes-app-express.git /home/ec2-user/notes-app-express
                cd /home/ec2-user/notes-app-express 
                npm install
                npm run build
                npm start
                EOF

  tags = {
    Name = "web-server-b-prod"
  }
}

# EC2 Instance - Web Server in Private Subnet A
resource "aws_instance" "web_server_private_a_prod" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_private_subnet_a_prod.id
  vpc_security_group_ids = [aws_security_group.web_sg_prod.id]

  user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "Hello World from $(hostname -f)!" > /var/www/html/index.html
                EOF

  tags = {
    Name = "web-server-private-a-prod"
  }
}

# EC2 Instance - Web Server in Private Subnet B
resource "aws_instance" "web_server_private_b_prod" {
  ami = "ami-0de02246788e4a354"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main_private_subnet_b_prod.id
  vpc_security_group_ids = [aws_security_group.web_sg_prod.id]

  user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "Hello World from $(hostname -f)!" > /var/www/html/index.html
                EOF

  tags = {
    Name = "web-server-private-b-prod"
  }
}

# Outputs

output "instance_public_ip_a" {
    description = "The Public IP of the EC2 Instance in Public Subnet A"
    value = aws_instance.web_server_a_prod.public_ip
}

output "instance_public_ip_b" {
    description = "The Public IP of the EC2 Instance in Public Subnet B"
    value = aws_instance.web_server_b_prod.public_ip
}
