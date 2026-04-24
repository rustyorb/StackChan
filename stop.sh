#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"
PID_FILE="$SERVER_DIR/.stackchan-server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "StackChan server PID file not found."
  exit 0
fi

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "StackChan server stopped: $PID"
else
  echo "StackChan server process not running: $PID"
fi

rm -f "$PID_FILE"
