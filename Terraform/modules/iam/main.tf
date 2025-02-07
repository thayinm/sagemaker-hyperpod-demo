# IAM ROLE for SageMaker

data "aws_iam_policy" "SageMakerFullAccess" {
  name = "AmazonSageMakerFullAccess"
}

data "aws_iam_policy" "PrometheusWriteAccess" {
  name = "AmazonPrometheusRemoteWriteAccess"
}

data "aws_iam_policy" "AmazonSageMakerClusterInstanceRolePolicy" {
  name = "AmazonSageMakerClusterInstanceRolePolicy"
}


resource "aws_iam_role" "sm_hyperpod_role" {
  name        = "sagemaker-execution-role"
  description = "SageMaker execution role with full access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TerraformSMAssume"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_attach" {
  role       = aws_iam_role.sm_hyperpod_role.name
  policy_arn = data.aws_iam_policy.PrometheusWriteAccess.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  role       = aws_iam_role.sm_hyperpod_role.name
  policy_arn = data.aws_iam_policy.SageMakerFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker_cluster_attach" {
  role       = aws_iam_role.sm_hyperpod_role.name
  policy_arn = data.aws_iam_policy.AmazonSageMakerClusterInstanceRolePolicy.arn
}

resource "aws_iam_role_policy" "hyperpod_vpc_policy" {
  name = "SageMakerHyperPodVPCAccess"
  role = aws_iam_role.sm_hyperpod_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DetachNetworkInterface"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "ec2:CreateTags"
        Resource = [
          "arn:aws:ec2:*:*:network-interface/*"
        ]
      }
    ]
  })
}
