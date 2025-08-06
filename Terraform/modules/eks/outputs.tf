output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.hyperpod_cluster.name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.hyperpod_cluster.arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.hyperpod_cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.hyperpod_cluster.certificate_authority[0].data
}
