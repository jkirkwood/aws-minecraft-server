#!/bin/bash

set -o errexit

region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".region")
bucket=$(aws ssm get-parameter --name "/minecraft-server/s3-bucket-name" --query "Parameter.Value" --output text --region "$region")

backup_name=world-$(date +%FT%H-%M-%S).tar.gz

# Create backup of world and important server config files and upload to S3
tar -C /home/ubuntu/minecraft -czf /tmp/world.tar.gz world banned-ips.json banned-players.json ops.json server.properties usercache.json whitelist.json
aws s3 cp /tmp/world.tar.gz "s3://${bucket}/backups/${backup_name}"
rm /tmp/world.tar.gz

echo "Created backup: ${backup_name}"