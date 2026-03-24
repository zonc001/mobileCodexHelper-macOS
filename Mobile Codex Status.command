#!/usr/bin/env bash
set -euo pipefail

cd "/Users/bring/Documents/New project/mobileCodexHelper"
./scripts/status-mobile-codex-macos.sh
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve status || true

echo
read -r -p "Press Enter to close this window..."
