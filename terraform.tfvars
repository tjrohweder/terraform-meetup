## General
environment = "Production"

## VPC
aws_region = "us-east-1"
vpc_cidr   = "172.35.0.0/16"

## EKS
cluster_name       = "Production"
workers_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsRSrvLQajvYLEWxHNnuso4OpeJf4LlRe5U3avtX9eccV0/p1LoFCXcBeHI2iedLMAULNiH+MTiFxZWNC6NklLzj/ckf7p5YrCa3gujwi7R7TIvgJG8/vmg58peusKj3Wgn+nvPgiYMtZyuTBFd8r15pFXmfy8IZVgSKxbnFv1DcIOEuqI4F4gRQBqTeCETCs7s1h0onnJYlUn8fIynGCxkqhtfapoqborldskYpBbPuzInTqFIOlgPBoMq/qb2uSric5VRH2gvdGHci7TAs7YTXG7W3F/XBpqJWrszMlNBQQFBjM7S9PECKMhvWeCOxLLOH28khxsJsl8eSFhd2i5"
eks_addons = {
  "vpc-cni"    = "v1.9.1-eksbuild.1"
  "kube-proxy" = "v1.21.2-eksbuild.2"
  "coredns"    = "v1.8.4-eksbuild.1"
}

## KMS
kms_deletion_window_in_days = 15
enable_key_rotation         = true


