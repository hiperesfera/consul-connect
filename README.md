# consul-connect
AWS Consul Connect lab

Terraforming a Consul-Connect enviroment in AWS for testing

The private subnet contains all Consul instances (clients and servers)
The public subnet contains the bastion host and load balancers
Outbound internet access from private subnet is done via NAT gateway in public subnet
variables.tf and tfstate files are omitted for security reasons
