#### Creating Consul Server on Ubuntu Server
resource "aws_instance" "consul-server" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  key_name = var.ssh_key
  security_groups = var.security_groups
  subnet_id     = var.subnet_id
  user_data = var.user_data

  tags = {
    Name = "consul-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}
