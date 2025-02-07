resource "aws_ssm_parameter" "prometheus_parameter" {
  name        = "/Terraform/Prometheus/WriteEndpoint"
  description = "Parameter for Prometheus managed by Terrafrom"
  type        = "String"
  value       = "${var.prometheus_endpoint}api/v1/remote_write"
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}

resource "aws_ssm_parameter" "private_subnet" {
  name        = "/Terraform/VPC/PrivateSubnet"
  description = "Parameter for VPC managed by Terrafrom"
  type        = "String"
  value       = var.private_subnet
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}

resource "aws_ssm_parameter" "security_group" {
  name        = "/Terraform/VPC/SecurityGroup"
  description = "Parameter for VPC managed by Terrafrom"
  type        = "String"
  value       = var.security_group
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}

resource "aws_ssm_parameter" "hyperpod_role" {
  name        = "/Terraform/IAM/HyperPodRole"
  description = "Parameter for IAM managed by Terrafrom"
  type        = "String"
  value       = var.hyperpod_role
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}

resource "aws_ssm_parameter" "hyperpod_bucket" {
  name        = "/Terraform/S3/HyperPodBucket"
  description = "Parameter for the S3 Bucket managed by Terrafrom"
  type        = "String"
  value       = var.hyperpod_bucket
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}


resource "aws_ssm_parameter" "hyperpod_fsx_mount_name" {
  name        = "/Terraform/FSx/HyperPodLustreMountName"
  description = "Parameter for the S3 Bucket managed by Terrafrom"
  type        = "String"
  value       = var.hyperpod_fsx_mount_name
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}

resource "aws_ssm_parameter" "hyperpod_fsx_dns_name" {
  name        = "/Terraform/FSx/HyperPodLustreDNSName"
  description = "Parameter for the S3 Bucket managed by Terrafrom"
  type        = "String"
  value       = var.hyperpod_fsx_dns_name
  tags = {
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terrafrom"
  }
}
