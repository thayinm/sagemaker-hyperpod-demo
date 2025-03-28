output "vpc_id" {
  value = aws_vpc.tf-sagemaker-vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "security_group_id" {
  value = aws_security_group.sg.id
}
