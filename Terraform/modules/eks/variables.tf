variable "private_subnets" {
  type        = list(string)
  description = "List of Private Subnets to deploy cluster into"
}

variable "eks_security_group_id" {
  type        = string
  description = "Security Group Id of VPC for Cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to be installed."
  default     = "1.32"
}

variable "resource_name_prefix" {
  description = "Prefix to be used for all resources created by this module"
  type        = string
  default     = "sagemaker-hyperpod-eks"
}
