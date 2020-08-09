
### Creating ELB
resource "aws_elb" "elb" {
  name = "consul-elb"
  security_groups = var.security_groups
  subnets = var.subnets

health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "TCP:8500"
}

  listener {
    lb_port = 80
    lb_protocol = "tcp"
    instance_port = "8500"
    instance_protocol = "tcp"
  }
}


### Creating ELB
resource "aws_elb" "elb_dashboard" {
  name = "dashboard-elb"
  security_groups = var.security_groups
  subnets = var.subnets

health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "TCP:9002"
}

  listener {
    lb_port = 80
    lb_protocol = "tcp"
    instance_port = "9002"
    instance_protocol = "tcp"
  }
}
