output "consul_server_id" {
  value = aws_instance.consul-server.id
}

output "consul_server_ip" {
  value = aws_instance.consul-server.private_ip
}
