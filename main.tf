provider "aws" {
  region = var.aws_region
}


// Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true 
    tags = {   
        Name = "dev-vpc"
    }
}

data "aws_availability_zones" "available" {
    state = "available"
  
}

// Creating Subnets
locals {
  azs = {
    Zone1 = {
      public_subnet_cidr  = "10.0.1.0/24"
      private_subnet_cidr = "10.0.3.0/24"
      az_index            = 0
      name = "AZ1 Subnets"
    }

    Zone2 = {
      public_subnet_cidr  = "10.0.2.0/24"
      private_subnet_cidr = "10.0.4.0/24"
      az_index            = 1
      name = "AZ2 Subnets"
    }
  }
}

resource "aws_subnet" "public" {
  for_each = local.azs
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.public_subnet_cidr
  map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[each.value.az_index]
    tags = {   
        Name = each.value.name
    }
}

resource "aws_subnet" "private" {
  for_each = local.azs
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.private_subnet_cidr
    availability_zone = data.aws_availability_zones.available.names[each.value.az_index]
    tags = {   
        Name = each.value.name
    }
}
// create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
    tags = {   
        Name = "Dev-igw"
    }
}   

// Create NAT Gateway
  
resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public
  domain = "vpc"
  tags = {
    Name = "Dev-nat-eip-${each.key}"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  for_each = aws_subnet.public
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id
    tags = {   
        Name = "Dev-nat-gw-${each.key}"
    }
    depends_on = [ aws_internet_gateway.igw ]
}

// Create Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"  
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {   
        Name = "Dev-public-rt"
    }
}   
resource "aws_route_table_association" "public_subnet" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[each.key].id
  }

  tags = {
    Name = "Dev-private-rt-${each.key}"
  }
}
resource "aws_route_table_association" "private_subnet" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

// Create Security Groups
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access to bastion host"
  vpc_id      = aws_vpc.main_vpc.id    
    tags = {   
        Name = "Dev-bastion-sg"
    }
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_bastion" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_bastion" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
    description = "Allow HTTP and SSH access to web servers"        
    vpc_id      = aws_vpc.main_vpc.id
    tags = {   
        Name = "Dev-web-sg"
    }
}
resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_web" {
  security_group_id            = aws_security_group.web_sg.id
  cidr_ipv4                    = "0.0.0.0/0"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_web" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_web" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
    description = "Allow MySQL access to database servers"        
    vpc_id      = aws_vpc.main_vpc.id
    tags = {   
        Name = "Dev-db-sg"
    }
}   
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_db" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_db" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_alb" {
  security_group_id            = aws_security_group.alb_sg.id
  cidr_ipv4                    = "0.0.0.0/0"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_https_alb" {
  security_group_id            = aws_security_group.alb_sg.id
  cidr_ipv4                    = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_alb" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
// Create EC2 Instances


resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "safia_key" {
  key_name   = "aws_key"
  public_key = tls_private_key.ssh_key.public_key_openssh

}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/my-key.pem"
  file_permission = "0600"
}
resource "aws_instance" "bastion" {
  ami           = "ami-0c94855ba95c71c99" // Amazon Linux 2 AMI
  for_each = aws_subnet.public
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public[each.key].id
  security_groups = [aws_security_group.bastion_sg.id]
  key_name      = aws_key_pair.safia_key.key_name
  associate_public_ip_address = false
    tags = {   
        Name = "Dev-bastion-${each.key}"
    }
  
}
resource "aws_eip" "bastion_eip" {
    for_each = aws_instance.bastion
    instance = each.value.id
    domain = "vpc"
    tags = {   
        Name = "Dev-bastion-eip-${each.key}"
    }
  
}
resource "aws_instance" "web_server" {
  ami           = "ami-0c94855ba95c71c99" // Amazon Linux 2 AMI
  for_each = aws_subnet.private
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.private[each.key].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = aws_key_pair.safia_key.key_name
  user_data = file("web_server_script.sh")
    tags = {   
        Name = "Dev-web-server-${each.key}"
    }
    depends_on = [ aws_nat_gateway.nat_gw]
}

resource "aws_instance" "db_server" {
  ami           = "ami-0c94855ba95c71c99" // Amazon Linux 2 AMI
  for_each = aws_subnet.private
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.private[each.key].id
  security_groups = [aws_security_group.db_sg.id]
  key_name      = aws_key_pair.safia_key.key_name
  user_data = file("db_server_script.sh")
    tags = {   
        Name = "Dev-db-server-${each.key}"
    }
    depends_on = [ aws_nat_gateway.nat_gw]
}


// Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  security_groups = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  load_balancer_type = "application"    
  tags = {   
        Name = "Dev-web-lb"
    }

}
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    matcher             = "200"
  }
  tags = {   
        Name = "Dev-web-tg" 
}
}
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"    
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.web_tg.arn
    }   
}
resource "aws_lb_target_group_attachment" "web_server_attachment" {
  for_each = aws_instance.web_server
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server[each.key].id
  port             = 80
}


