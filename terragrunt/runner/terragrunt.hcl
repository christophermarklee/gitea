locals {
  aws_region   = get_env("AWS_REGION", "us-east-1")
  github_owner = get_env("GITHUB_REPOSITORY_OWNER", "")
  github_repo  = get_env("GITHUB_REPO_NAME", "gitea")
  runner_name  = "gitea-runner"
}

# Remote state stored in S3 (bucket must be pre-created)
remote_state {
  backend = "s3"
  config = {
    bucket         = get_env("TF_STATE_BUCKET", "gitea-tf-state")
    key            = "runner/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = get_env("TF_LOCK_TABLE", "gitea-tf-lock")
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  source = "../../terraform/runner"
}

inputs = {
  aws_region                = local.aws_region
  github_owner              = local.github_owner
  github_repo               = local.github_repo
  runner_name               = local.runner_name
  runner_registration_token = get_env("RUNNER_REGISTRATION_TOKEN", "")
}
