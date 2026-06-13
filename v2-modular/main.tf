
# call vpc module
module "vpc" {
  source = "./modules/vpc"
}

# Create security module
module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id # bind with above vpc module
}

# call the ALB module
module "alb" {
  source          = "./modules/alb"
  vpc_id          = module.vpc.vpc_id
  alb_sg_id       = module.security.alb_sg_id
  public_subnet_a = module.vpc.public_subnet_a
  public_subnet_b = module.vpc.public_subnet_b
  log_bucket      = aws_s3_bucket.alb_logs.bucket
}

# Call ASG module
module "asg" {
  source           = "./modules/asg"
  ec2_sg_id        = module.security.ec2_sg_id
  private_app_a    = module.vpc.private_app_a
  private_app_b    = module.vpc.private_app_b
  target_group_arn = module.alb.target_group_arn
}

# Call RDS module
module "rds" {
  source       = "./modules/rds"
  private_db_a = module.vpc.private_db_a
  private_db_b = module.vpc.private_db_b
  rds_sg_id    = module.security.rds_sg_id
}





# Create cloudwatch CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = module.asg.autoscaling_group_name
  }
  alarm_description = "Trigger when CPU > 80%"

}

# Create Autoscaling policies

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = module.asg.autoscaling_group_name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = module.asg.autoscaling_group_name
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
    AutoScalingGroupName = module.asg.autoscaling_group_name
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
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Caret3 s3 bucket for ALB LOG store
resource "aws_s3_bucket" "alb_logs" {

  bucket = "malshan-alb-logs-12345"

  tags = {
    Name = "alb-log-bucket"
  }
}

# Add log bucket policies to store logs
resource "aws_s3_bucket_policy" "alb_logs" {

  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
      }
    ]
  })
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