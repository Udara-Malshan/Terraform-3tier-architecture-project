# get the ALB DNS name for search
output "alb_dns_name" {

  value = aws_lb.app_alb.dns_name
}

 # get the RDS endpoint
output "rds_endpoint" {

  value = aws_db_instance.mysql.endpoint
}