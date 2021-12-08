provider "aws" {
  region     = "us-east-1"
}

module "main-vpc" {
  source       = "./modules/aws-vpc"
  vpc_cidr     = var.vpc_cidr
  vpc_name     = var.environment
  nat_count    = 1
  cluster_name = var.cluster_name
  environment  = var.environment
  aws_region   = var.aws_region
}

module "eks-production" {
  source                      = "./modules/aws-eks"
  cluster_name                = var.cluster_name
  eks_version                 = "1.21"
  private_subnets             = module.main-vpc.private_subnets
  vpc_id                      = module.main-vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  worker_instance_type        = "m5a.large"
  worker_volume_size          = 30
  worker_volume_type          = "gp3"
  workers_public_key          = var.workers_public_key
  kms_deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation         = var.enable_key_rotation
  eks_addons                  = var.eks_addons
  ingress_controller_policy   = "files/ingress_controller_policy.json"
  cluster_autoscaler_policy   = "files/cluster_autoscaler_policy.json"
}