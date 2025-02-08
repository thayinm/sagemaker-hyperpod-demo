resource "aws_fsx_lustre_file_system" "fsx_lustre_hyperpod" {
  subnet_ids       = [var.private_subnet]
  storage_capacity = 1200
  storage_type = "SSD"
  per_unit_storage_throughput = 250
  deployment_type = "PERSISTENT_2"
  log_configuration {
    level = "WARN_ERROR"
}
  tags = {
    Name = "TerraformLustreFileSystem"
    Environment = "SageMakerHyperPod"
    CreatedBy   = "Terraform"
  }
}
