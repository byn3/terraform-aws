variable "region" {
  description = "AWS Deployment region.."
  default     = "us-west-2"
}

variable "vpc1" {
  description = "VPC1 cidr block"
  default     = "10.100.0.0/16"
}

variable "public_subnet" {
  description = "public subnet cidr block"
  default     = "10.100.1.0/24"
}

variable "private_subnet" {
  description = "private subnet cidr block"
  default     = "10.100.9.0/24"
}

variable "ami" {
  description = "ami ubuntu"
  default     = "ami-08692d171e3cf02d6"
}

variable "instance_type" {
  description = "instance type, t2 micro"
  default     = "t2.micro"
}
