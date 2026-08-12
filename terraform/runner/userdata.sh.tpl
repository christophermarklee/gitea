#!/usr/bin/env bash
# Bootstrap script for GitHub Actions self-hosted runner on Ubuntu 22.04
set -euo pipefail

### System packages ###
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  curl \
  jq \
  git \
  unzip \
  docker.io \
  awscli

systemctl enable --now docker
usermod -aG docker ubuntu

### GitHub Actions runner ###
RUNNER_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
  | jq -r '.tag_name' | sed 's/v//')
RUNNER_DIR=/home/ubuntu/actions-runner

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

curl -fsSLo runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz"
tar xzf runner.tar.gz
rm runner.tar.gz

chown -R ubuntu:ubuntu "$RUNNER_DIR"

sudo -u ubuntu ./config.sh \
  --url "https://github.com/${github_owner}/${github_repo}" \
  --token "${registration_token}" \
  --name "${runner_name}" \
  --labels "${runner_labels}" \
  --unattended \
  --replace

./svc.sh install ubuntu
./svc.sh start
