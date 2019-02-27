#!/bin/bash

set -o errexit

# Start the minecraft server. Allocate 75% of the server's RAM
total_mem=$(free | grep "Mem" | awk '{print $2}')
mem=$((total_mem*3/4*1024))

echo "Starting minecraft server with $mem bytes of RAM"
java -Xmx${mem} -Xms${mem} -jar /home/ubuntu/minecraft/server.jar
