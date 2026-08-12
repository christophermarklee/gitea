output "instance_id" {
  description = "EC2 instance ID of the self-hosted runner"
  value       = aws_instance.runner.id
}

output "public_ip" {
  description = "Public IP address of the self-hosted runner"
  value       = aws_instance.runner.public_ip
}

output "runner_name" {
  description = "Name assigned to the GitHub Actions runner"
  value       = var.runner_name
}
