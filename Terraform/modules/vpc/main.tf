# VPC Infrastructure
resource "aws_vpc" "tf-sagemaker-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "terraform-VPC",
    auto-delete = "no",
    CreatedBy   = "Terraform"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.tf-sagemaker-vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name                                         = "terraform-public-subnet-${count.index + 1}",
    CreatedBy                                    = "Terraform",
    "kubernetes.io/cluster/hyperpod-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.tf-sagemaker-vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name                                         = "terraform-private-subnet-${count.index + 1}",
    CreatedBy                                    = "Terraform"
    "kubernetes.io/cluster/hyperpod-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tf-sagemaker-vpc.id

  tags = {
    Name      = "terraform-IG",
    CreatedBy = "Terraform"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.tf-sagemaker-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "terraform-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second_rt.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)

  tags = {
    Name      = "terraform-NAT",
    CreatedBy = "Terraform"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tf-sagemaker-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name      = "terraform-private-route-table",
    CreatedBy = "Terraform"
  }
}

resource "aws_route_table_association" "private_subnet_asso" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "sg" {
  name        = "terraform-sagemaker-SG"
  description = "Security Group managed by Terraform"
  vpc_id      = aws_vpc.tf-sagemaker-vpc.id

  # Inbound rule
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # ingress {
  #   from_port = 443
  #   to_port   = 443
  #   protocol  = "tcp"
  #   self      = true
  # }

  # ingress {
  #   from_port = 8192
  #   to_port   = 65535
  #   protocol  = "tcp"
  #   self      = true
  # }

  # ingress {
  #   from_port = 2049
  #   to_port   = 2049
  #   protocol  = "tcp"
  #   self      = true
  # }

  # Outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
