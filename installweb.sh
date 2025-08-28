#!/usr/bin/env bash

# Improved install script for onyxia/web when apt repositories are unreliable.
#
# - Undviker att `apt-get update` orsakar fel genom att inte köra update.
#   Försöker först installera nodejs och npm direkt från distributionen.
#   Vid behov används NodeSource som fallback.
# - Installerar Yarn Classic via corepack (om tillgängligt) eller npm.
# - Ökar Yarn-nätverkstimeouten för att undvika ESOCKETTIMEDOUT.
# - Navigerar till UI-projektet relativt till skriptets egen placering.
# - Ger instruktioner för hur man startar utvecklingsservern via Onyxia-proxy.

set -euo pipefail

# Använd sudo om det finns, annars kör som root
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "[*] Checking for node ..."
if ! command -v node >/dev/null 2>&1; then
  echo "[!] Node not found. Attempting to install via apt (nodejs + npm)."
  # Försök installera nodejs och npm från distributionen utan apt-get update
  if ! ${SUDO} apt-get install -y --no-install-recommends nodejs npm 2>/dev/null; then
    echo "[!] Distro installation failed. Falling back to NodeSource (20.x)."
    # Installera minimala beroenden för NodeSource
    ${SUDO} apt-get install -y --no-install-recommends ca-certificates curl gnupg
    # Kör NodeSource-setup. Ignorera fel från tredjeparts-PPAs.
    if curl -fsSL https://deb.nodesource.com/setup_20.x | ${SUDO} -E bash -; then
      ${SUDO} apt-get install -y nodejs
    else
      echo "[ERROR] NodeSource setup failed due to repository errors."
      exit 1
    fi
  fi
else
  echo "[*] Node is already installed: $(node -v)"
fi

# Verifiera Node-installation
if ! command -v node >/dev/null 2>&1; then
  echo "[ERROR] Node installation was not successful."
  exit 1
fi

echo "[*] Setting up Yarn..."
if command -v corepack >/dev/null 2>&1; then
  # Aktivera corepack och förbered Yarn Classic (v1)
  ${SUDO} corepack enable
  ${SUDO} corepack prepare yarn@1.x --activate
else
  # Fallback: installera Yarn globalt via npm
  ${SUDO} npm install -g yarn
fi

# Sätt global Yarn-timeout (default 10 minuter)
YARN_TIMEOUT="${YARN_TIMEOUT:-600000}"
yarn config set network-timeout "${YARN_TIMEOUT}" -g || true

# Hitta skriptets katalog och navigera till UI-subprojektet relativt till denna
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/web"

echo "[*] Installing npm dependencies with Yarn (timeout ${YARN_TIMEOUT} ms)..."
yarn install --network-timeout "${YARN_TIMEOUT}"

echo "[+] Dependency installation completed successfully."
echo "    To start the development server:"
echo "     yarn dev --host $(hostname -I | awk '{print $1}') --port 3000"
