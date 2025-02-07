variable "prometheus_endpoint" {
  type = string
  description = "The RemoteWrite Endpoint URL from Prometheus WorkSpace"
}

variable "private_subnet" {
  type = string
  description = "The Private Subnet to use for our HyperPod Cluster"
}

variable "security_group" {
  type = string
  description = "The Security Group to be associated with the HyperPod Cluster"
}

variable "hyperpod_role" {
  type = string
  description = "The IAM Role that our HyperPod Cluster will use to provision itself"
}

variable "hyperpod_bucket" {
  type = string
  description = "The bucket in which to store the HyperPod Clusters Lifecycle Config."
}
