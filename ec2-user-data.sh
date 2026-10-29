#!/bin/bash
# One-time setup for an Ubuntu LTS (24.04 or 26.04) EC2 host. Paste as EC2 "User data" at launch, or run
# once over SSH with `sudo bash ec2-user-data.sh`. Progress: /var/log/cloud-init-output.log
set -eux

# 4 GB swap: 2 GB RAM (t3.small) is tight for the Maven build next to Postgres
if [ ! -f /swapfile ]; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Docker from Ubuntu's own archive; git ships with the image
apt-get update
apt-get install -y docker.io docker-compose-v2 docker-buildx
usermod -aG docker ubuntu
