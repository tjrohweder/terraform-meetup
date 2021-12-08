variable "cluster_name" {
  description = "Name of EKS cluster"
}

variable "eks_version" {
  description = "Version of EKS cluster. It will be replicated for Worker nodes"
}

variable "private_subnets" {
  description = "List of private subnets for the cluster"
}

variable "vpc_id" {
  description = "VPC ID  where EKS will be created in"
}

variable "vpc_cidr" {
  description = "VPC network range"
}

variable "ingress_controller_policy" {
  description = "Policy document for AWS Ingress Controller"
}

variable "cluster_autoscaler_policy" {
  description = "Policy document for EKS cluster autoscaler"
}

variable "worker_instance_type" {
  description = "EKS worker instance type"
}

variable "worker_volume_size" {
  description = "Disk size for root block device"
}

variable "worker_volume_type" {
  description = "Disk type for root block device"
}

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
