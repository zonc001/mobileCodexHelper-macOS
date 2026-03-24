#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tailscale_bin="${TAILSCALE_BIN:-/Applications/Tailscale.app/Contents/MacOS/Tailscale}"

cd "$workspace"

if [[ -x "$tailscale_bin" ]]; then
  echo "Disabling Tailscale Serve ..."
  "$tailscale_bin" serve reset >/dev/null 2>&1 || true
fi

./scripts/stop-mobile-codex-macos.sh
