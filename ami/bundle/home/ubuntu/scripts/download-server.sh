#!/bin/bash

# Check the currently installed version of minecraft server jar, and download
# update if available

set -o errexit

installed_url_path=/home/ubuntu/minecraft/installed_url

installed_url=""

if [[ -e $installed_url_path ]]; then
  installed_url=$(cat $installed_url_path)
fi

latest_url=$(curl -s https://minecraft.net/en-us/download/server/ | grep -m 1 -oP "https://.*?jar")

echo "Latest server url: $latest_url"
echo "Installed server url: $installed_url"

if [[ $installed_url != "$latest_url" ]]; then
  echo "Installing new version of minecraft server"
  wget "$latest_url" -O /home/ubuntu/minecraft/server.jar
  echo "$latest_url" > $installed_url_path
else
  echo "Installed minecraft server version up to date"
fi