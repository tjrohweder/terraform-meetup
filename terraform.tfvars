## General
environment = "Production"

## VPC
aws_region  = "us-east-1"
vpc_cidr    = "172.35.0.0/16"

## EKS
cluster_name       = "Production"
workers_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAaDAQABAAABAQDSHfc9y1Ke1EsO6miYCUyS9IzjU8DdffxDe19/4aC1Mw237TLjWPkiUt1/VR8lbmTvL3aWzcA5Jrbzz99LqfdixgSq1j6/OnnbfdMsQ4T/dp15q9pV6TlqSAS9lsdOgCVIjRYHoVcAnHWob/OK+MgyMXOGfmMGrDMN4p3EpVAEF5CDktzPZniwOnCNLMVMU73JCgqFumeHTdaB0pfMIY+anOTsLt+5UonaaENF9wWnxaxkqOO6sbUaVyslab7Pdtxa3KJ1GYm9lu26bDB8vCDwG5dNt/ABPSJ6KPPROoEW5dS6r7HAx/3LvUyupVcvPUwGl9gZZP8OWuxjG/u6zriqb"
eks_addons = {
  "vpc-cni"    = "v1.9.0-eksbuild.1"
  "kube-proxy" = "v1.21.2-eksbuild.2"
  "coredns"    = "v1.8.4-eksbuild.1"
}

## KMS
kms_deletion_window_in_days = 15
enable_key_rotation         = true


