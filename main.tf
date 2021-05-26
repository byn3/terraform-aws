terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
}


/* # part 1 set up VPC, subnets, gateway, route table */
/*

PART 1

*/

resource "aws_vpc" "vpc1" {
  cidr_block       = var.vpc1
  instance_tenancy = "default"

  tags = {
    Name = "vpc1"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.internet_gateway]
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = true


  tags = {
    Name = "public subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.private_subnet
  map_public_ip_on_launch = false


  tags = {
    Name = "private subnet"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public_ass" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_ass" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}



/*

Part 2 set up ec2 and SG

*/



resource "aws_instance" "web_server" {
  ami           = var.ami
  instance_type = var.instance_type

  provisioner "remote-exec" {
    script = "puppet.sh"
  }

  tags = {
    Name = "ExampleWebServer"
  }
}

resource "aws_security_group" "Web" {
  name        = "Web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}



/*

PArt 3 AUTO SCALING

*/



resource "aws_placement_group" "cluster" {
  name     = "cluster"
  strategy = "partition"
}

resource "aws_launch_configuration" "template" {
  name          = "template"
  image_id      = var.ami
  instance_type = var.instance_type
}

resource "aws_autoscaling_group" "Web_ASG" {
  name                      = "Web_ASG"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  placement_group           = aws_placement_group.cluster.id
  launch_configuration      = aws_launch_configuration.template.name
  vpc_zone_identifier       = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

}



/*

PART 4 ALB


*/
/*
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Web.id]
  subnets = aws_subnet.public_subnet.*.id
}

end. need to make 2 subnets in same vpc, diff avail zones for this alb above.

*/
