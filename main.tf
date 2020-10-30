provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}



data "template_file" "consul_client_dashboard" {
  template = "${file("./bootstrap_scripts/consul_client_dashboard.sh")}"
  vars = {
    consul_server_address = "${module.consul_server.consul_server_ip}"
    PSK = var.consul_encrypt
  }
}

data "template_file" "consul_client_dashboard_prd" {
  template = "${file("./bootstrap_scripts/consul_client_dashboard_prd.sh")}"
  vars = {
    consul_server_address = "${module.consul_server.consul_server_ip}"
    PSK = var.consul_encrypt
  }
}

data "template_file" "consul_client_backend" {
  template = "${file("./bootstrap_scripts/consul_client_backend.sh")}"
  vars = {
    consul_server_address = "${module.consul_server.consul_server_ip}"
    PSK = var.consul_encrypt
  }
}

data "template_file" "consul_client_backend_prd" {
  template = "${file("./bootstrap_scripts/consul_client_backend_prd.sh")}"
  vars = {
    consul_server_address = "${module.consul_server.consul_server_ip}"
    PSK = var.consul_encrypt
  }
}

data "template_file" "consul_server" {
  template = "${file("./bootstrap_scripts/consul_server.sh")}"
  vars = {
    PSK = var.consul_encrypt
  }
}


##### Creating BASTION-HOST in public subnet
resource "aws_key_pair" "ssh-key" {
  key_name = "ssh-key"
  public_key = file("./terraform-keys.pub")
}

module "vpc" {
      source = "./vpc"
      availabilityZone = var.availabilityZone
      region           = var.region
}

module "acls" {
      source = "./acls"
      vpc = module.vpc.vpc_id
      subnets = [module.vpc.public_subnet_id]
      home_isp_jesus = var.jesus_home
}

module "elbs" {
      source = "./elbs"
      security_groups = [module.acls.consul_connect_server_elb_security_group]
      subnets = [module.vpc.public_subnet_id]
}

module "bastion" {
      source = "./bastion"
      security_groups = [module.acls.consul_connect_bastion_security_group]
      subnet_id = module.vpc.public_subnet_id
      ssh_key = aws_key_pair.ssh-key.key_name
}


module "consul_server" {
      source = "./consul_server"
      security_groups = [module.acls.consul_connect_security_group]
      subnet_id = module.vpc.public_subnet_id
      user_data = "${data.template_file.consul_server.rendered}"
      ssh_key = aws_key_pair.ssh-key.key_name
}


module "consul_client_frontend" {

      source = "./consul_client"
      security_groups = [module.acls.consul_connect_security_group]
      subnet_id = module.vpc.public_subnet_id
      ssh_key = aws_key_pair.ssh-key.key_name
      number_of_servers = 1
      //consul_server_ip = module.consul_server.consul_server_ip
      user_data = "${data.template_file.consul_client_dashboard.rendered}"
}


module "consul_client_frontend_prd" {

      source = "./consul_client"
      security_groups = [module.acls.consul_connect_security_group]
      subnet_id = module.vpc.public_subnet_id
      ssh_key = aws_key_pair.ssh-key.key_name
      number_of_servers = 1
      //consul_server_ip = module.consul_server.consul_server_ip
      user_data = "${data.template_file.consul_client_dashboard_prd.rendered}"
}


module "consul_client_backend" {

      source = "./consul_client"
      security_groups = [module.acls.consul_connect_security_group]
      subnet_id = module.vpc.public_subnet_id
      ssh_key = aws_key_pair.ssh-key.key_name
      number_of_servers = 1
      //consul_server_ip = module.consul_server.consul_server_ip
      user_data = "${data.template_file.consul_client_backend.rendered}"
}


module "consul_client_backend_prd" {

      source = "./consul_client"
      security_groups = [module.acls.consul_connect_security_group]
      subnet_id = module.vpc.public_subnet_id
      ssh_key = aws_key_pair.ssh-key.key_name
      number_of_servers = 1
      //consul_server_ip = module.consul_server.consul_server_ip
      user_data = "${data.template_file.consul_client_backend_prd.rendered}"
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "aws_consul_server_elb_attachment" {
  elb      = module.elbs.consul_server_elb
  instance = module.consul_server.consul_server_id
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "aws_dashboard_server_elb_attachment" {
  count = 1
  elb      = module.elbs.dashboard_server_elb
  instance = "${element(module.consul_client_frontend.consul_client_id,count.index)}"
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "aws_dashboard_server_elb_attachment_prd" {
  count = 1
  elb      = module.elbs.dashboard_server_elb_prd
  instance = "${element(module.consul_client_frontend_prd.consul_client_id,count.index)}"
}


# Printing endpoints
output "consul_server_elb_dns_name" {
  value       = module.elbs.consul_server_elb_dns_name
  description = "The domain name of the load balancer"
}

output "dashboard_server_elb_dns_name" {
  value       = module.elbs.dashboard_server_elb_dns_name
  description = "The domain name of the load balancer"
}

output "dashboard_server_elb_dns_name_prd" {
  value       = module.elbs.dashboard_server_elb_dns_name_prd
  description = "The domain name of the load balancer"
}
