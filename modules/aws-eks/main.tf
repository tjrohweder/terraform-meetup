data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "this_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:jenkinsci:jenkins"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this_assume_role_policy.json
  name               = "WebID"
}

resource "aws_iam_role" "eks" {
  name = "eks"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH

apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

locals {
  eks_subnets = slice(var.private_subnets, 0, 4)
}

locals {
  workers_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role" "node" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "Node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "Node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "Node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "Node-AmazonIngressController" {
  policy_arn = aws_iam_policy.ingress_controller.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_policy" "ingress_controller" {
  name        = "ingress-controller"
  path        = "/"
  description = "AWS Ingress Controller Policy"

  policy = file(var.ingress_controller_policy)
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "cluster-autoscaler"
  path        = "/"
  description = "EKS cluster autoscaler policy"

  policy = file(var.cluster_autoscaler_policy)
}

resource "aws_security_group" "eks" {
  name   = "eks"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKS Control Plane"
  }
}

resource "aws_security_group_rule" "eks_ingress-workstation-https" {
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks.id
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group" "node" {
  name   = "worker-node"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "Worker Nodes Security Group",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "prod_node_ingress-workstation-https" {
  cidr_blocks       = [var.vpc_cidr]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  to_port           = 0
  type              = "ingress"
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version  = var.eks_version

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.secrets.arn
    }
  }

  vpc_config {
    security_group_ids      = [aws_security_group.eks.id]
    subnet_ids              = [for value in local.eks_subnets : value]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_AmazonEKSServicePolicy,
  ]
}

resource "aws_eks_node_group" "eks" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [for value in var.private_subnets : value]

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = 3
    max_size     = 30
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 25
  }

  depends_on = [
    aws_iam_role_policy_attachment.Node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.Node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.Node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "TRUE"
  }
}

resource "aws_launch_template" "node" {
  name                   = "worker-nodes"
  image_id               = data.aws_ami.eks-worker.id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.eks-worker-nodes.key_name
  vpc_security_group_ids = [aws_security_group.node.id]
  ebs_optimized          = true
  user_data              = base64encode(local.workers_userdata)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.worker_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}"
    }
  }
}

resource "aws_key_pair" "eks-worker-nodes" {
  key_name   = "${var.cluster_name}-nodes"
  public_key = var.workers_public_key
}

resource "aws_eks_addon" "this" {
  for_each          = var.eks_addons
  cluster_name      = aws_eks_cluster.eks.name
  addon_name        = each.key
  addon_version     = each.value
  resolve_conflicts = "OVERWRITE"
}
