#!/bin/bash

# This script is run on the build server and installs all necessary files,
# packages, etc

set -o errexit

# Update and install packages
sudo apt-get update
sudo apt-get -yq upgrade
sudo apt-get -yq install git awscli openjdk-8-jre jq

# Extract bundle files
sudo tar -C / -zxvpof /tmp/bundle.tar.gz && rm /tmp/bundle.tar.gz

# Update home dir permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu

# Enable services
sudo systemctl enable create-backup.service
sudo systemctl enable download-server.service
sudo systemctl enable init-dns.service
sudo systemctl enable minecraft-server.service
sudo systemctl enable shutdown-monitor.service
