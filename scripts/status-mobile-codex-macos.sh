#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_dir="$workspace/.runtime/macos"
pid_file="$runtime_dir/mobile-codex.pid"
db_path="${DATABASE_PATH:-$runtime_dir/auth.db}"
host="${HOST:-127.0.0.1}"
port="${PORT:-3001}"
health_url="http://$host:$port/health"

echo "Workspace: $workspace"
echo "Database: $db_path"

if [[ -f "$pid_file" ]]; then
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "Process: running (PID $pid)"
  else
    echo "Process: stale pid file"
  fi
else
  echo "Process: not running"
fi

if command -v curl >/dev/null 2>&1; then
  if response="$(curl -fsS "$health_url" 2>/dev/null)"; then
    echo "Health: ok"
    echo "Health URL: $health_url"
    echo "Response: $response"
  else
    echo "Health: unavailable"
    echo "Health URL: $health_url"
  fi
else
  echo "Health: curl not found"
fi
