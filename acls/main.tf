# create security groups consult_connect
resource "aws_security_group" "consul_connect" {
  name        = "consul_connect_server"
  description = "consul_connect_server security group"
  vpc_id      = var.vpc

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}

# create security groups consult_connect ELB
resource "aws_security_group" "consul_connect_server_elb" {
  name        = "consul_connect_server_elb"
  description = "consul_connect_server ELB security group"
  vpc_id      = var.vpc

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}




# create security group bastion host
resource "aws_security_group" "consul_connect_bastion" {
  name        = "consul_connect_bastion"
  description = "consul_connect_bastion security group"
  vpc_id      = var.vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}


# create VPC Network access control list
resource "aws_network_acl" "vpc_NACLs" {
    vpc_id = var.vpc
    subnet_ids = var.subnets

    ingress {
      protocol   = "-1"
      rule_no    = 100
      action     = "allow"
      cidr_block = var.home_isp_jesus
      from_port  = 0
      to_port    = 0
    }

    ingress {
      protocol   = "-1"
      rule_no    = 200
      action     = "allow"
      cidr_block = "10.0.0.0/16"
      from_port  = 0
      to_port    = 0
    }

    ingress {
      protocol   = "tcp"
      rule_no    = 300
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 32768
      to_port    = 65535
    }

    # allow egress ephemeral ports
    egress {
      protocol   = "-1"
      rule_no    = 300
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
}
