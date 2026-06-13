# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = [
    var.private_db_a, 
    var.private_db_b
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
    var.rds_sg_id
  ]

  publicly_accessible = false
  skip_final_snapshot  = true

  tags = {
    Name = "app-mysql"
  }
}