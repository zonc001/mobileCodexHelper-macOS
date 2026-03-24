#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tailscale_bin="${TAILSCALE_BIN:-/Applications/Tailscale.app/Contents/MacOS/Tailscale}"
local_url="${LOCAL_URL:-http://127.0.0.1:3001}"

if [[ ! -x "$tailscale_bin" ]]; then
  echo "Tailscale CLI not found: $tailscale_bin" >&2
  echo "Set TAILSCALE_BIN if your install path is different." >&2
  exit 1
fi

cd "$workspace"
./scripts/start-mobile-codex-macos.sh

echo "Enabling Tailscale Serve for $local_url ..."
"$tailscale_bin" serve reset >/dev/null 2>&1 || true
"$tailscale_bin" serve --bg "$local_url"

serve_status="$("$tailscale_bin" serve status)"
remote_url="$(printf '%s\n' "$serve_status" | awk '/https:\/\// {print $1; exit}')"

echo
echo "Remote access is ready."
if [[ -n "$remote_url" ]]; then
  echo "Phone URL: $remote_url"
else
  echo "Phone URL: not detected automatically"
fi
echo
printf '%s\n' "$serve_status"
