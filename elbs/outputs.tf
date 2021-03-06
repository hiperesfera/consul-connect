
output "consul_server_elb" {
  value = aws_elb.elb.id
}

output "dashboard_server_elb_dev" {
  value = aws_elb.elb_dashboard_dev.id
}

output "dashboard_server_elb_prd" {
  value = aws_elb.elb_dashboard_prd.id
}

output "consul_server_elb_dns_name" {
  value       = aws_elb.elb.dns_name
  description = "The domain name of Consule server load balancer"
}

output "dashboard_server_elb_dns_name_dev" {
  value       = aws_elb.elb_dashboard_dev.dns_name
  description = "The domain name of the dashbaord load balancer"
}

output "dashboard_server_elb_dns_name_prd" {
  value       = aws_elb.elb_dashboard_prd.dns_name
  description = "The domain name of the dashbaord load balancer"
}
