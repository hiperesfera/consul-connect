

output "consul_connect_server_elb_security_group" {
  value = aws_security_group.consul_connect_server_elb.id
}

output "consul_connect_security_group" {
  value = aws_security_group.consul_connect.id
}


output "consul_connect_bastion_security_group" {
  value = aws_security_group.consul_connect_bastion.id
}
