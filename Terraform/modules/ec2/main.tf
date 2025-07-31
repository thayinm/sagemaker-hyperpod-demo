# Find latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}


# Create security group for Grafana
resource "aws_security_group" "grafana_sg" {
  name        = "${var.name_prefix}-grafana-sg"
  description = "Security group for Grafana server"
  vpc_id      = var.vpc_id

  # Grafana web interface
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    description = "Grafana web access"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "SSH access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name_prefix}-grafana-sg"
  }
}

# Create EC2 instance
resource "aws_instance" "grafana" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.grafana_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_profile

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install required dependencies
    yum install -y wget
    
    # Add Grafana repository
    cat > /etc/yum.repos.d/grafana.repo << 'EOL'
    [grafana]
    name=grafana
    baseurl=https://packages.grafana.com/oss/rpm
    repo_gpgcheck=1
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.grafana.com/gpg.key
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    EOL
    
    # Install Grafana
    yum install -y grafana
    
    # Enable and start Grafana service
    systemctl daemon-reload
    systemctl enable grafana-server
    systemctl start grafana-server
    
    # Configure firewall if enabled
    if systemctl is-active --quiet firewalld; then
      firewall-cmd --permanent --add-port=3000/tcp
      firewall-cmd --reload
    fi
    
    # Display installation completion message
    echo "Grafana installation completed. Access at http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
    echo "Default credentials: admin/admin"
  EOF

  tags = {
    Name = "${var.name_prefix}-grafana-server"
  }
}
