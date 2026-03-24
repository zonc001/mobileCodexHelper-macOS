#!/usr/bin/env bash
set -euo pipefail

cd "/Users/bring/Documents/New project/mobileCodexHelper"
python3 ./scripts/device-approval-cli.py list

echo
read -r -p "Press Enter to close this window..."
