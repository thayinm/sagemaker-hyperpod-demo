output "sagemaker_role_arn" {
  value = aws_iam_role.sm_hyperpod_role.arn
}

output "grafana_role_arn" {
  value = aws_iam_role.grafana_ec2_role.arn
}

output "grafana_instance_profile" {
  value = aws_iam_instance_profile.grafana_instance_profile.name
}
