#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
upstream_dir="${MOBILE_CODEX_UPSTREAM_DIR:-$workspace/vendor/claudecodeui-1.25.2}"
runtime_dir="$workspace/.runtime/macos"
log_dir="$runtime_dir/logs"
pid_file="$runtime_dir/mobile-codex.pid"
db_path="${DATABASE_PATH:-$runtime_dir/auth.db}"
host="${HOST:-127.0.0.1}"
port="${PORT:-3001}"
node_bin="${MOBILE_CODEX_NODE:-$(command -v node || true)}"
stdout_log="$log_dir/mobile-codex.stdout.log"
stderr_log="$log_dir/mobile-codex.stderr.log"

mkdir -p "$log_dir"

if [[ -z "$node_bin" ]]; then
  echo "Node.js not found on PATH. Set MOBILE_CODEX_NODE if needed." >&2
  exit 1
fi

if [[ ! -d "$upstream_dir" ]]; then
  echo "Upstream checkout not found: $upstream_dir" >&2
  exit 1
fi

if [[ ! -d "$upstream_dir/node_modules" ]]; then
  echo "Dependencies not installed. Run: cd \"$upstream_dir\" && npm install" >&2
  exit 1
fi

if [[ ! -f "$upstream_dir/dist/index.html" ]]; then
  echo "Production build not found. Run: cd \"$upstream_dir\" && npm run build" >&2
  exit 1
fi

if [[ -f "$pid_file" ]]; then
  existing_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "mobileCodexHelper is already running: PID $existing_pid"
    echo "URL: http://$host:$port"
    exit 0
  fi
  rm -f "$pid_file"
fi

touch "$stdout_log" "$stderr_log"
printf '\n==== START %s ====\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$stdout_log"
printf '\n==== START %s ====\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$stderr_log"

cd "$upstream_dir"
if command -v setsid >/dev/null 2>&1; then
  env \
    DATABASE_PATH="$db_path" \
    HOST="$host" \
    PORT="$port" \
    CODEX_ONLY_HARDENED_MODE="${CODEX_ONLY_HARDENED_MODE:-true}" \
    VITE_CODEX_ONLY_HARDENED_MODE="${VITE_CODEX_ONLY_HARDENED_MODE:-true}" \
    setsid "$node_bin" server/index.js </dev/null >>"$stdout_log" 2>>"$stderr_log" &
else
  env \
    DATABASE_PATH="$db_path" \
    HOST="$host" \
    PORT="$port" \
    CODEX_ONLY_HARDENED_MODE="${CODEX_ONLY_HARDENED_MODE:-true}" \
    VITE_CODEX_ONLY_HARDENED_MODE="${VITE_CODEX_ONLY_HARDENED_MODE:-true}" \
    nohup "$node_bin" server/index.js </dev/null >>"$stdout_log" 2>>"$stderr_log" &
fi
pid="$!"
disown "$pid" 2>/dev/null || true
echo "$pid" > "$pid_file"

pid="$(cat "$pid_file")"
health_url="http://$host:$port/health"

for _ in {1..20}; do
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "mobileCodexHelper failed to start. Check logs:" >&2
    echo "  $stdout_log" >&2
    echo "  $stderr_log" >&2
    exit 1
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -fsS "$health_url" >/dev/null 2>&1; then
      echo "mobileCodexHelper started successfully."
      echo "PID: $pid"
      echo "URL: http://$host:$port"
      echo "Database: $db_path"
      echo "Logs:"
      echo "  $stdout_log"
      echo "  $stderr_log"
      exit 0
    fi
  fi

  sleep 1
done

echo "mobileCodexHelper started, but health check did not pass in time." >&2
echo "PID: $pid" >&2
echo "Check logs:" >&2
echo "  $stdout_log" >&2
echo "  $stderr_log" >&2
exit 1
