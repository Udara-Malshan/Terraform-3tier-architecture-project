# Create ALB Security group

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

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
  vpc_id      = var.vpc_id

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
  vpc_id      = var.vpc_id

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
