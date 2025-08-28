#!/usr/bin/env bash

# Robust installation script for Onyxia web UI (onyxia/web)
#
# This script installs a modern Node.js runtime and Yarn package manager,
# then runs `yarn install` for the UI project with a generous network timeout
# to avoid `ESOCKETTIMEDOUT` errors. It uses corepack when available to
# provide Yarn Classic (v1) because the project relies on it. If corepack
# isn't available, it falls back to installing Yarn via npm.

set -euo pipefail

# Pick sudo if present. On Onyxia pods, passwordless sudo is usually
# available. Otherwise leave empty to run commands as the current user (root).
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# Update apt metadata quietly and install minimal tools for Node installation.
# Do not pass -y to `apt-get update` because it isn't interactive; instead
# use -y only with `install`. Avoid large recommends packages to keep
# images lean.
DEBIAN_FRONTEND=noninteractive ${SUDO} apt-get update -qq
${SUDO} apt-get install -y --no-install-recommends ca-certificates curl gnupg

# Install Node.js 20.x via NodeSource if Node isn't already installed.
# If NodeSource fails (e.g. network restrictions), fall back to the distro's
# nodejs/npm packages.
if ! command -v node >/dev/null 2>&1; then
  if curl -fsSL https://deb.nodesource.com/setup_20.x | ${SUDO} -E bash -; then
    ${SUDO} apt-get install -y nodejs
  else
    echo "Warning: NodeSource repository could not be reached. Falling back to distro packages."
    ${SUDO} apt-get install -y nodejs npm
  fi
fi

# Verify Node installation
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js installation failed."
  exit 1
fi
echo "Using Node $(node -v)"

# Enable corepack and prepare Yarn Classic (1.x). Corepack is shipped with
# Node 16+ and manages package managers such as Yarn and pnpm. Activating
# Yarn via corepack ensures a deterministic, up-to-date installation.
if command -v corepack >/dev/null 2>&1; then
  ${SUDO} corepack enable
  # Use Yarn Classic (1.x) because the onyxia/web project relies on the
  # classic workflow. Adjust version if needed.
  ${SUDO} corepack prepare yarn@1.x --activate
else
  # Fall back to installing Yarn globally via npm
  ${SUDO} npm install -g yarn
fi

# Increase Yarn network timeout to reduce ESOCKETTIMEDOUT errors.
# YARN_TIMEOUT can be overridden by the caller; default is 10 minutes (600000 ms).
YARN_TIMEOUT="${YARN_TIMEOUT:-600000}"
yarn config set network-timeout "${YARN_TIMEOUT}" -g || true

# Navigate to project directory. Assumes this script lives in the repository root
# and that the `onyxia/web` subdirectory contains the UI project.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/onyxia/web"

# Install dependencies. The explicit --network-timeout flag is passed
# in case per-project configuration overrides the global setting. Yarn v1
# accepts this flag; subsequent versions will ignore it gracefully.
yarn install --network-timeout "${YARN_TIMEOUT}"

echo "Dependency installation complete. You can now run the development server with:"
echo "    yarn dev --host 0.0.0.0 --port 3000"