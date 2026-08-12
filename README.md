# gitea

Gitea self-hosted deployment on AWS using Terraform / Terragrunt.

## Overview

| # | Workflow | Trigger |
|---|----------|---------|
| 01 | **Create AWS Self-Hosted Runner** – provisions an EC2 instance and registers it as a GitHub Actions runner | Manual |
| 02 | **Terragrunt Init / Plan / Apply** – runs init-upgrade, plan, and optionally apply/destroy | Manual or `push` to `main` |
| 03 | **Update Self-Hosted Runner** – waits for the runner to come online and triggers an update | Automatic (after 01) |
| 04 | **Deploy Gitea Docker** – pulls and runs the `gitea/gitea` container on the self-hosted runner | Automatic (after 03) or manual |
| 05 | **Backup Gitea to S3 Glacier** – creates a `tar.gz` of the Gitea data directory and uploads to S3 Glacier | Scheduled (daily 02:00 UTC) or manual |

## Required repository secrets and variables

| Name | Type | Description |
|------|------|-------------|
| `AWS_ROLE_ARN` | Secret | IAM role ARN for OIDC federation |
| `GH_PAT` | Secret | GitHub personal access token (runner registration) |
| `AWS_REGION` | Variable | AWS region (default: `us-east-1`) |
| `TF_STATE_BUCKET` | Variable | S3 bucket for Terraform remote state |
| `TF_LOCK_TABLE` | Variable | DynamoDB table for Terraform state locking |
| `BACKUP_BUCKET` | Variable | S3 bucket for Gitea backups |

## Infrastructure layout

```
terraform/runner/   – Terraform module (EC2, VPC, IAM, Security Group)
terragrunt/runner/  – Terragrunt wrapper (remote state, inputs)
.github/workflows/  – GitHub Actions pipelines
```
