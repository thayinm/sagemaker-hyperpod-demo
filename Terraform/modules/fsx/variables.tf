variable "private_subnet" {
  type = string
  description = "Private Subnet ID for making the filesystem available to the cluster."
}

variable "security_group_ids" {
  type = string
  description = "Security Group ID that is also used by the Cluster"
}
