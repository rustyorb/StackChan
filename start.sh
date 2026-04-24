#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"
PID_FILE="$SERVER_DIR/.stackchan-server.pid"
LOG_FILE="$SERVER_DIR/.stackchan-server.log"
BIN_FILE="$SERVER_DIR/.stackchan-server"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE")"
  if kill -0 "$PID" 2>/dev/null; then
    echo "StackChan server already running: $PID"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

cd "$SERVER_DIR"
go build -o "$BIN_FILE" main.go
nohup "$BIN_FILE" >"$LOG_FILE" 2>&1 &
echo "$!" >"$PID_FILE"
echo "StackChan server started: $(cat "$PID_FILE")"
echo "Log: $LOG_FILE"
