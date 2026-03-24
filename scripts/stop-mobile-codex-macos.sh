#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_dir="$workspace/.runtime/macos"
pid_file="$runtime_dir/mobile-codex.pid"

if [[ ! -f "$pid_file" ]]; then
  echo "mobileCodexHelper is not running."
  exit 0
fi

pid="$(cat "$pid_file" 2>/dev/null || true)"
if [[ -z "$pid" ]]; then
  rm -f "$pid_file"
  echo "Removed empty pid file."
  exit 0
fi

if kill -0 "$pid" 2>/dev/null; then
  kill "$pid"
  for _ in {1..10}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$pid_file"
      echo "Stopped mobileCodexHelper (PID $pid)."
      exit 0
    fi
    sleep 1
  done

  kill -9 "$pid" 2>/dev/null || true
  rm -f "$pid_file"
  echo "Force-stopped mobileCodexHelper (PID $pid)."
  exit 0
fi

rm -f "$pid_file"
echo "Removed stale pid file for PID $pid."
