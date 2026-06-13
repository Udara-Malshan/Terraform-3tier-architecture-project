# Create VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "3tier-vpc"
  }
}

# Create public subnet a
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-a"
  }
}

# Create public subnet b (in another AZ)
resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-b"
  }
}

# Careate Private Subnet a
resource "aws_subnet" "private_app_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-app-a"
  }
}

# Create Private Subnet b
resource "aws_subnet" "private_app_b" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-app-b"
  }
}

# Create DB Subnet a
resource "aws_subnet" "private_db_a" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-db-a"
  }
}

# Create DB Subnet b
resource "aws_subnet" "private_db_b" {

  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.22.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-db-b"
  }
}

# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create Public Route table (for IGW)
resource "aws_route_table" "public_rt" {
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Public Subnet a to IGW
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Public subnet b to IGW
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private-rt
resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

# Associate Private Subnets to private rt
resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate DB subnets also to private rt
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Create EIP for NAT gateway
resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "main-NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Add route to Private rt for NGW (0.0.0.0/0 -> NAT Gateway)
resource "aws_route" "private_default" {

  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

# Create ALB Security group

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {

    from_port = 80   # http allow
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 443    # https allow
    to_port = 443
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
    Name = "alb-sg"
  }
}

# Create sg for ec2

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for ec2"
  vpc_id      = aws_vpc.main.id

  ingress {

    from_port = 80
    to_port = 80
    protocol = "tcp"

    security_groups = [
      aws_security_group.alb_sg.id      # can access only through alb sg
    ]
  }

  egress {

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Create sg for RDS

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security roup for RDS"
  vpc_id      = aws_vpc.main.id

ingress {

    from_port = 3306      # mysql port
    to_port = 3306
    protocol = "tcp"

    security_groups = [
      aws_security_group.ec2_sg.id     #RDS can only access through ec2
    ]
  }

  egress {

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

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
    aws_security_group.ec2_sg.id
  ]

  user_data = base64encode(
    file("${path.module}/userdata/install.sh")
  )

  monitoring {
  enabled = true
  }

  tags = {
    Name = "app-template"
  }
}

# Create Target group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {

    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }
}

# Create auto scaling group (for scalability according to traffic)
resource "aws_autoscaling_group" "app_asg" {

  name = "app-asg"
  desired_capacity = 2
  min_size = 2   # therefor, when start automatically create 2 ec2s in private subnets using before created launch template
  max_size = 4
  vpc_zone_identifier = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.app_tg.arn
  ]

  launch_template {         # when scale,create ec2 using this launch template
    id = aws_launch_template.app.id 
    version = "$Latest"
  }

  health_check_type = "EC2"
}


# Create Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
    ]

  tags = {
    Name = "app-alb"
  }
}

# Create listner for the ALB (this listening to the request and forword to Target group)

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Attach ASG to Traget group - this already added in ASG.
# if we create manually ec2 instances,we need to attach them to traget group manually


# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.private_db_a.id, 
    aws_subnet.private_db_b.id
    ]

  tags = {
    Name = "DB-subnet-group"
  }
}

# Create RDS
resource "aws_db_instance" "mysql" {
  
  identifier = "app-mysql"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage    = 20
  username             = "user"
  password             = "Malshan123!"

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  publicly_accessible = false
  skip_final_snapshot  = true

  tags = {
    Name = "app-mysql"
  }
}

# Create cloudwatch CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "high-cpu-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_description         = "Trigger when CPU > 80%"
  
}

# Create Autoscaling policies

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# Attach policies to cloudwatch
resource "aws_cloudwatch_metric_alarm" "cpu_high" {

  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}


# Create s3 for versioning and store tfstate 
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-3tier-state-bucket-12345"

}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB lock table create for block simultanious executing the terraform
resource "aws_dynamodb_table" "tf_lock" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Backend Configure
terraform {
  backend "s3" {
    bucket         = "my-terraform-3tier-state-bucket-12345"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}