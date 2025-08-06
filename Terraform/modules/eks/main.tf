# Node Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.resource_name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.resource_name_prefix}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach managed policy to the role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
    role = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# EKS cluster
resource "aws_eks_cluster" "hyperpod_cluster" {
  name     = "hyperpod-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version  

  vpc_config {
    subnet_ids             = var.private_subnets
    endpoint_public_access = true
    endpoint_private_access = true
    security_group_ids     = [var.eks_security_group_id]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
}

resource "aws_launch_template" "eks_node" {
  name = "${var.resource_name_prefix}-node-template"
  vpc_security_group_ids = [var.eks_security_group_id]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.hyperpod_cluster.name
  node_group_name = "${var.resource_name_prefix}-private-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnets
  instance_types  = ["t3.small"]

  launch_template {
    id      = aws_launch_template.eks_node.id
    version = aws_launch_template.eks_node.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.hyperpod_cluster.name
  addon_name        = "vpc-cni"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.hyperpod_cluster.name
  addon_name        = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.hyperpod_cluster.name
  addon_name        = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_group
  ]

}

resource "aws_eks_addon" "pod_identity" {
  cluster_name      = aws_eks_cluster.hyperpod_cluster.name
  addon_name        = "eks-pod-identity-agent"
}
