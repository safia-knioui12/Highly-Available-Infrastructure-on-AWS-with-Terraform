# Highly-Available-Infrastructure-on-AWS-with-Terraform
How to Build a Highly Available Infrastructure on AWS with Terraform
The Architecture:
-- A Virtual Private Cloud (VPC) with public and private subnets across multiple availability zones
-- Web servers in private subnets (hidden from direct internet access)
-- A load balancer distributing traffic across web servers
-- A database server in a private subnet
-- A bastion host for secure administrative access
-- NAT Gateways to allow private servers to reach the internet for updates
