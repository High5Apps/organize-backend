#!/bin/sh
set -e

watch_dir=/etc/nginx/ssl/live

while true; do
  echo "Waiting for changes to files in $watch_dir..."
  inotifywait --event modify --event moved_to --event create $watch_dir

  echo "File changes detected. Validating Nginx configuration..."
  nginx -t

  if [ $? -eq 0 ]; then
    echo "Nginx configuration valid. Reloading..."
    nginx -s reload
  fi
done
