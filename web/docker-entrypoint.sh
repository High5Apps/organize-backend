#!/bin/sh
set -e

# Run in the background in a non-login, non-interactive, shell
sh -c "./nginx-auto-reloader.sh &"

exec "$@"
