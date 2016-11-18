variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

variable "aws_region" {
  description = "AWS region to deploy to launch servers"
  default = "eu-west-1"
}

variable "aws_amis" {
  default = {
    "eu-west-1" = "ami-07174474"
    "eu-central-1" = "ami-82cf0aed"
  }
}

variable "availability_zones" {
  default     = "eu-west-1b,eu-west-1c,eu-west-1a"
  description = "List of availability zones, use AWS CLI to find your "
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "4"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "1"
}
