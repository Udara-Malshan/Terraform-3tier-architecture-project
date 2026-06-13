# Create Target group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {

    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }
}

# Create Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [
    var.public_subnet_a,
    var.public_subnet_b
    ]


  access_logs {               # keep logs in s3 bucket about ALB visitors
    bucket  = var.log_bucket
    enabled = true
  }

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