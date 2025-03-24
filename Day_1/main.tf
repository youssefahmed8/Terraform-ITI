resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-terraform-iti"
  }
}

resource "aws_subnet" "Sub" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-terraform"
  }
}

resource "aws_route_table" "routeTable_ITI" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public_Route_Table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}


resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.Sub.id
  route_table_id = aws_route_table.routeTable_ITI.id
}

resource "aws_security_group" "apache_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Apache_SG"
  }
}


resource "aws_instance" "apache_ec2" {
  ami           = "ami-08b5b3a93ed654d19" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Sub.id
  security_groups = [aws_security_group.apache_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello this is Jou from ec2 running using Terraform </h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Apache_EC2"
  }
}



