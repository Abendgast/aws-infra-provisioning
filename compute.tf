resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "core_vm" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.shared.id
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.core_sg.id]
  tags = { Name = "CoreServicesVM" }
}

resource "aws_instance" "mfg_vm" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.sensor1.id
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.mfg_sg.id]
  tags = { Name = "ManufacturingVM" }
}

resource "aws_launch_template" "vmss" {
  name_prefix   = "az104-vmss-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.main.key_name
  network_interfaces {
    security_groups = [aws_security_group.core_sg.id]
  }
}

resource "aws_autoscaling_group" "vmss" {
  vpc_zone_identifier = [aws_subnet.shared.id, aws_subnet.db.id]
  desired_capacity    = 2
  max_size            = 10
  min_size            = 2

  launch_template {
    id      = aws_launch_template.vmss.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.vmss.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Scales out above 70%, scales in below automatically
  }
}
