#!/bin/bash

# Check number of active connections to Minecraft server (port 25565) every
# minute. If not connections exist for 10 minutes, shut down the server.

initial_countdown_value=10
minutes_to_shutdown=$initial_countdown_value

# Shutdown server if no minecraft connections present for 30 minutes
while ((minutes_to_shutdown > 0)); do
  num_connections=$(netstat -anp | grep :25565 | grep -c ESTABLISHED)

  echo "Detected $num_connections connections to minecraft"

  if ((num_connections < 1)); then
    minutes_to_shutdown=$((minutes_to_shutdown - 1))
    echo "Shutting down in $minutes_to_shutdown minutes"
  else
    echo "Resetting shutdown timer"
    minutes_to_shutdown=$initial_countdown_value
  fi

  sleep 60;
done

echo "Shutting down now"
shutdown -h now