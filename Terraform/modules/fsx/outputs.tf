output "fsx_dns_name" {
  value = aws_fsx_lustre_file_system.fsx_lustre_hyperpod.dns_name
}

output "fsx_mount_name" {
  value = aws_fsx_lustre_file_system.fsx_lustre_hyperpod.mount_name
}

output "fsx_filesystem_id" {
  value = aws_fsx_lustre_file_system.fsx_lustre_hyperpod.id
}
