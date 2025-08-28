#!/usr/bin/env bash

# Script to launch the onyxia web UI development server.
#
# It navigates into the `web/` subdirectory and runs `yarn dev` on a host and port.
# Host is derived from `hostname -I`, port defaults to 3000 unless PORT is set.
# Using exec ensures that signals (e.g. CTRL+C) are forwarded to yarn.

set -euo pipefail

# Find the directory where this script resides
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}/web"

PORT="${PORT:-3000}"
HOST=$(hostname -I | awk '{print $1}')

echo "[*] Starting yarn dev on ${HOST}:${PORT} (web/) …"

# Replace the shell with the yarn process
exec yarn dev --host "${HOST}" --port "${PORT}"
