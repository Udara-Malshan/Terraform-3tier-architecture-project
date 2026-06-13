# Find amazon linux latest ami
data "aws_ami" "amazon_linux" {

  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = [
      "al2023-ami-*-x86_64"
    ]
  }
}


# Create launch template
resource "aws_launch_template" "app" {

  name_prefix = "app-template"
  image_id = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name = "terraform-key"
  vpc_security_group_ids = [
    var.ec2_sg_id
  ]

  user_data = base64encode(
    file("modules/asg/userdata/install.sh")
  )

  monitoring {
  enabled = true
  }

  tags = {
    Name = "app-template"
  }
}

# Create auto scaling group (for scalability according to traffic)
resource "aws_autoscaling_group" "app_asg" {

  name = "app-asg"
  desired_capacity = 2
  min_size = 2   # therefor, when start automatically create 2 ec2s in private subnets using before created launch template
  max_size = 4
  vpc_zone_identifier = [
    var.private_app_a,
    var.private_app_b
  ]

  target_group_arns = [
    var.target_group_arn
  ]

  launch_template {         # when scale,create ec2 using this launch template
    id = aws_launch_template.app.id 
    version = "$Latest"
  }

  health_check_type = "EC2"
}