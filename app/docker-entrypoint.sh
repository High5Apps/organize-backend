#!/bin/bash
set -e

PID_FILE_PATH=tmp/pids/server.pid

if [ -f $PID_FILE_PATH ]; then
  rm $PID_FILE_PATH
fi

exec bundle exec "$@"
