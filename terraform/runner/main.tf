terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################################
# Data
###############################################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# Networking (single-AZ, minimal)
###############################################################################

resource "aws_vpc" "runner" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.runner_name}-vpc"
    ManagedBy   = "terraform"
  }
}

resource "aws_internet_gateway" "runner" {
  vpc_id = aws_vpc.runner.id

  tags = {
    Name      = "${var.runner_name}-igw"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "runner" {
  vpc_id                  = aws_vpc.runner.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.runner_name}-subnet"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "runner" {
  vpc_id = aws_vpc.runner.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.runner.id
  }

  tags = {
    Name      = "${var.runner_name}-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "runner" {
  subnet_id      = aws_subnet.runner.id
  route_table_id = aws_route_table.runner.id
}

###############################################################################
# Security group
###############################################################################

resource "aws_security_group" "runner" {
  name        = "${var.runner_name}-sg"
  description = "GitHub self-hosted runner"
  vpc_id      = aws_vpc.runner.id

  ingress {
    description = "Gitea HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Gitea SSH"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.runner_name}-sg"
    ManagedBy = "terraform"
  }
}

###############################################################################
# IAM role for SSM access (no SSH required)
###############################################################################

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${var.runner_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner" {
  name = "${var.runner_name}-profile"
  role = aws_iam_role.runner.name
}

###############################################################################
# EC2 instance
###############################################################################

resource "aws_instance" "runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.runner.id
  vpc_security_group_ids = [aws_security_group.runner.id]
  iam_instance_profile   = aws_iam_instance_profile.runner.name

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/userdata.sh.tpl", {
    github_owner       = var.github_owner
    github_repo        = var.github_repo
    runner_name        = var.runner_name
    runner_labels      = var.runner_labels
    registration_token = var.runner_registration_token
  })

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name      = var.runner_name
    ManagedBy = "terraform"
  }
}
