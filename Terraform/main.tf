terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

module "sagemaker_vpc" {
  source = "./modules/vpc"
}

module "sagemaker_role" {
  source = "./modules/iam"
}

module "prometheus_workspace" {
  source = "./modules/prometheus"
}

module "s3_hyperpod_bucket" {
  source = "./modules/s3"
}

module "fsx_lustre" {
  source             = "./modules/fsx"
  private_subnet     = module.sagemaker_vpc.private_subnet_ids[0]
  security_group_ids = module.sagemaker_vpc.security_group_id
}

module "parameter_store" {
  source                  = "./modules/parameter_store"
  prometheus_endpoint     = module.prometheus_workspace.prometheus_workspace_endpoint
  private_subnet          = module.sagemaker_vpc.private_subnet_ids[0]
  hyperpod_role           = module.sagemaker_role.sagemaker_role_arn
  security_group          = module.sagemaker_vpc.security_group_id
  hyperpod_bucket         = module.s3_hyperpod_bucket.hyperpod_bucket
  hyperpod_fsx_mount_name = module.fsx_lustre.fsx_mount_name
  hyperpod_fsx_dns_name   = module.fsx_lustre.fsx_dns_name
}

module "grafana" {
  source      = "./modules/ec2"
  subnet_id   = module.sagemaker_vpc.public_subnet_ids[0]
  vpc_id      = module.sagemaker_vpc.vpc_id
  key_name    = "docker-sandbox"
  iam_profile = module.sagemaker_role.grafana_instance_profile
}
