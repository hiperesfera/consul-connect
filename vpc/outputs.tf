output "vpc_id" {
  value = aws_vpc.public.id
}

output "public_subnet_id" {
  value = aws_subnet.consult_connect_subnet_public.id
}

output "private_subnet_id" {
  value = aws_subnet.consult_connect_subnet_private.id
}
