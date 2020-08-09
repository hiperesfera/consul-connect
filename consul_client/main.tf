#### Creating Consul Client on Ubuntu Server
resource "aws_instance" "consul-client" {

  count = var.number_of_servers

  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  key_name = var.ssh_key
  security_groups = var.security_groups
  subnet_id     = var.subnet_id

  user_data = var.user_data

  tags = {
    Name = "consul-client-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
  }
}
