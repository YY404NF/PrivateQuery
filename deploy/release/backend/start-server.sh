#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p data logs run

start_server() {
  local name="$1"
  local env_file="$2"
  local binary="$3"
  local pid_file="$SCRIPT_DIR/run/${name}.pid"
  local log_file="$SCRIPT_DIR/logs/${name}.log"
  local pid=""

  if [[ ! -f "$SCRIPT_DIR/$env_file" ]]; then
    echo "missing env file: $env_file" >&2
    exit 1
  fi

  if [[ ! -x "$SCRIPT_DIR/$binary" ]]; then
    echo "missing executable binary: $binary" >&2
    exit 1
  fi

  if [[ -f "$pid_file" ]]; then
    pid="$(<"$pid_file")"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "$name is already running with pid $pid"
      return
    fi
    rm -f "$pid_file"
  fi

  (
    set -a
    source "$SCRIPT_DIR/$env_file"
    set +a
    nohup setsid "$SCRIPT_DIR/$binary" >>"$log_file" 2>&1 < /dev/null &
    echo $! >"$pid_file"
  )

  sleep 1
  pid="$(<"$pid_file")"
  if kill -0 "$pid" 2>/dev/null; then
    echo "started $name with pid $pid, log: logs/${name}.log"
    return
  fi

  echo "failed to start $name, check logs/${name}.log" >&2
  exit 1
}

case "${1:-all}" in
  a|server-a)
    start_server "server-a" "server-a.env" "server-a"
    ;;
  b|server-b)
    start_server "server-b" "server-b.env" "server-b"
    ;;
  all)
    start_server "server-a" "server-a.env" "server-a"
    start_server "server-b" "server-b.env" "server-b"
    ;;
  *)
    echo "usage: ./start-server.sh [all|a|b|server-a|server-b]" >&2
    exit 1
    ;;
esac
