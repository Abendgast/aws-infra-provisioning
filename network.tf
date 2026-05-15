# Requirement: Lab 4 (Virtual Networking) & Lab 5 (Intersite Connectivity) - Maps to Azure VNet and VNet Peering spec
resource "aws_vpc" "core" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "CoreServicesVnet" }
}

resource "aws_subnet" "shared" {
  vpc_id            = aws_vpc.core.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "SharedServicesSubnet" }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.core.id
  cidr_block        = "10.20.20.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "DatabaseSubnet" }
}

resource "aws_vpc" "mfg" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "ManufacturingVnet" }
}

resource "aws_subnet" "sensor1" {
  vpc_id            = aws_vpc.mfg.id
  cidr_block        = "10.30.20.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "SensorSubnet1" }
}

resource "aws_subnet" "sensor2" {
  vpc_id            = aws_vpc.mfg.id
  cidr_block        = "10.30.21.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "SensorSubnet2" }
}

resource "aws_internet_gateway" "core_igw" {
  vpc_id = aws_vpc.core.id
}
resource "aws_internet_gateway" "mfg_igw" {
  vpc_id = aws_vpc.mfg.id
}

resource "aws_route_table" "core_rt" {
  vpc_id = aws_vpc.core.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.core_igw.id
  }
}
resource "aws_route_table_association" "shared_rt_assoc" {
  subnet_id      = aws_subnet.shared.id
  route_table_id = aws_route_table.core_rt.id
}
resource "aws_route_table_association" "db_rt_assoc" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.core_rt.id
}

resource "aws_route_table" "mfg_rt" {
  vpc_id = aws_vpc.mfg.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mfg_igw.id
  }
}
resource "aws_route_table_association" "sensor1_rt_assoc" {
  subnet_id      = aws_subnet.sensor1.id
  route_table_id = aws_route_table.mfg_rt.id
}
resource "aws_route_table_association" "sensor2_rt_assoc" {
  subnet_id      = aws_subnet.sensor2.id
  route_table_id = aws_route_table.mfg_rt.id
}

resource "aws_vpc_peering_connection" "core_mfg" {
  peer_vpc_id = aws_vpc.mfg.id
  vpc_id      = aws_vpc.core.id
  auto_accept = true
  tags = { Name = "Core-Manufacturing-Peering" }
}

resource "aws_route" "core_to_mfg" {
  route_table_id            = aws_route_table.core_rt.id
  destination_cidr_block    = aws_vpc.mfg.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.core_mfg.id
}

resource "aws_route" "mfg_to_core" {
  route_table_id            = aws_route_table.mfg_rt.id
  destination_cidr_block    = aws_vpc.core.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.core_mfg.id
}

resource "aws_security_group" "core_sg" {
  name        = "CoreServicesSG"
  description = "Allow inbound HTTP and SSH"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

resource "aws_security_group" "mfg_sg" {
  name        = "MfgServicesSG"
  description = "Allow inbound HTTP and SSH for Mfg VNet"
  vpc_id      = aws_vpc.mfg.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

# Requirement: Lab 6 (Traffic Management) - Maps to Azure Application Gateway spec
resource "aws_lb" "main" {
  name               = "az104-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.core_sg.id]
  subnets            = [aws_subnet.shared.id, aws_subnet.db.id]
}

resource "aws_lb_target_group" "images" {
  name     = "images-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.core.id
}

resource "aws_lb_target_group" "videos" {
  name     = "videos-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.core.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default Path"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "images" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.images.arn
  }
  condition {
    path_pattern {
      values = ["/image/*"]
    }
  }
}

resource "aws_lb_listener_rule" "videos" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.videos.arn
  }
  condition {
    path_pattern {
      values = ["/video/*"]
    }
  }
}
