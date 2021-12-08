variable "vpc_cidr" {
  description = "Network range of the VPC"
  default     = ""
}

variable "vpc_name" {
  description = "Name of the VPC to be created"
  default     = ""
}

variable "nat_count" {
  description = "Number of NAT Gateways. For best HA, each NAT Gateway will be created in a different AZ"
  default     = ""
}

variable "cluster_name" {}
variable "aws_region" {}
variable "environment" {}
