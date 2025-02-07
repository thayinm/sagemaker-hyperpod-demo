resource "aws_prometheus_workspace" "hyperpod_prometheus_workspace" {
  alias = "tf-hyperpod-workspace"

  tags = {
    Environment = "SageMakerHyperPod",
    CreatedBy = "Terraform"
  }
}
