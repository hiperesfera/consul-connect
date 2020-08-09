resource "aws_instance" "bastion" {
  ami           = "ami-0b4b2d87bdd32212a"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  key_name = var.ssh_key
  security_groups = var.security_groups
  subnet_id     = var.subnet_id

  tags = {
    Name = "bastion-host"
  }
}
