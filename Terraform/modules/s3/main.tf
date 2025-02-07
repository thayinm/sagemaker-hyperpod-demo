data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "aws_s3_bucket" "hyperpod_bucket" {
  bucket = "${data.aws_region.current.name}-sagemaker-hyperpod-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    CreatedBy        = "Terraform"
    Environment = "SagemakerHyperPod"
  }
}
