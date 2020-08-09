output "consul_client_id" {
  value = "${aws_instance.consul-client.*.id}"
}
