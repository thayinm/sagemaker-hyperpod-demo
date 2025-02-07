output "prometheus_workspace_endpoint" {
  value = aws_prometheus_workspace.hyperpod_prometheus_workspace.prometheus_endpoint
}
