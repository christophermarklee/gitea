variable "aws_region" {
  description = "AWS region to deploy the runner into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the runner VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the runner subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the runner"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size_gb" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 40
}

variable "runner_name" {
  description = "Name used for the GitHub runner and AWS resources"
  type        = string
  default     = "gitea-runner"
}

variable "runner_labels" {
  description = "Comma-separated list of labels for the GitHub Actions runner"
  type        = string
  default     = "self-hosted,linux,x64,aws"
}

variable "github_owner" {
  description = "GitHub organisation or user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "Repository name (without owner) where the runner is registered"
  type        = string
}

variable "runner_registration_token" {
  description = "Short-lived runner registration token obtained from the GitHub API"
  type        = string
  sensitive   = true
}
