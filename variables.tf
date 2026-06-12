variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "my_ip" {
  description = "My Ip address for SSH to bastion"
  type = string
}
variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}
variable "web_instance_type" {
  description = "EC2 instance type for web servers" 
  type        = string
  default     = "t3.micro"
}
variable "db_instance_type" {
  description = "EC2 instance type for database servers"
  type        = string
  default     = "t3.small"
}
variable "key_name" {
    description = "Name of the SSH key pair to use for EC2 instances"
    type        = string
    default = "aws_key"
}
