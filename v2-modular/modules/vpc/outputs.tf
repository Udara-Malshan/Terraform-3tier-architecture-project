output "vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet_a" {
    value = aws_subnet.public_a.id
}

output "public_subnet_b" {
    value = aws_subnet.public_b.id
}

output "private_app_a" {
    value = aws_subnet.private_app_a.id
 }

 output "private_app_b" {
    value = aws_subnet.private_app_b.id
 }

 output "private_db_a" {
    value = aws_subnet.private_db_a.id
 }

 output "private_db_b" {
    value = aws_subnet.private_db_b.id
 }