variable "vpc_cidr" {}
variable "aws_region" {}
variable "environment" {}
variable "cluster_name" {}
variable "workers_public_key" {
  description = "Public key portion to be used for SSH access"
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion time"
}

variable "enable_key_rotation" {
  description = "Enable KMS key roation. Valid values: true or false"
  type        = bool
}

variable "eks_addons" {
  type = map(any)
}