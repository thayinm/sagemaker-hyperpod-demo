terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
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

module "parameter_store" {
  source              = "./modules/parameter_store"
  prometheus_endpoint = module.prometheus_workspace.prometheus_workspace_endpoint
  private_subnet      = module.sagemaker_vpc.private_subnet_ids[0]
  hyperpod_role       = module.sagemaker_role.sagemaker_role_arn
  security_group      = module.sagemaker_vpc.security_group_id
  hyperpod_bucket     = module.s3_hyperpod_bucket.hyperpod_bucket
}