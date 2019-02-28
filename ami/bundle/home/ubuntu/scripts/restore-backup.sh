#!/bin/bash

set -o errexit

# Pass name of backup file to script as first argument
backup_name=$1

region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".region")
bucket=$(aws ssm get-parameter --name "/minecraft-server/s3-bucket-name" --query "Parameter.Value" --output text --region "$region")

# Remove current local world backup and move existing world folder
rm /home/ubuntu/minecraft/world-backup || true
mv /home/ubuntu/minecraft/world /home/ubuntu/minecraft/world-backup

# Download backup from S3 and apply to minecraft directory
aws s3 cp "s3://${bucket}/backups/${backup_name}" /tmp/world.tar.gz
tar -C /home/ubuntu/minecraft -xzf /tmp/world.tar.gz

echo "Applied backup: ${backup_name}"