#!/usr/bin/env bash
set -euo pipefail

# Använd sudo om det finns
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# 1. Kommentera bort raden med ubuntugis-ppa (hindrar apt-get update från att avbryta)
for file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
  if [ -f "$file" ]; then
    ${SUDO} sed -i.bak '/ubuntugis.*ppa/ s/^/#/' "$file" || true
  fi
done

echo "[*] Checking for node ..."
if ! command -v node >/dev/null 2>&1; then
  echo "[!] Node not found. Attempting to install via apt (nodejs + npm)."
  # Försök installera nodejs och npm utan att köra update
  if ! ${SUDO} apt-get install -y --no-install-recommends nodejs npm 2>/dev/null; then
    echo "[!] Distro installation failed. Falling back to NodeSource (20.x)."
    ${SUDO} apt-get install -y --no-install-recommends ca-certificates curl gnupg
    # NodeSource-setup gör en apt-get update internt; nu lyckas den eftersom PPA är kommenterad
    curl -fsSL https://deb.nodesource.com/setup_20.x | ${SUDO} -E bash -
    ${SUDO} apt-get install -y nodejs
  fi
else
  echo "[*] Node is already installed: $(node -v)"
fi

# Kontrollera Node
command -v node >/dev/null || { echo "[ERROR] Node installation failed."; exit 1; }

# 2. Se till att npm finns
if ! command -v npm >/dev/null; then
  echo "[*] npm not found. Installing via apt…"
  ${SUDO} apt-get install -y npm || {
    echo "[ERROR] Npm installation failed. You may need to fix apt repositories or install NodeSource.";
    exit 1;
  }
fi

echo "[*] Setting up Yarn..."
if command -v corepack >/dev/null 2>&1; then
  ${SUDO} corepack enable
  ${SUDO} corepack prepare yarn@1.x --activate
else
  ${SUDO} npm install -g yarn
fi

# Set network timeout
YARN_TIMEOUT="${YARN_TIMEOUT:-600000}"
yarn config set network-timeout "${YARN_TIMEOUT}" -g || true

# Navigera relativt till skriptets plats
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/web"

echo "[*] Installing dependencies…"
yarn install --network-timeout "${YARN_TIMEOUT}"

echo "[+] Done."
echo "  Start dev-server with:"
echo "  yarn dev --host $(hostname -I | awk '{print $1}') --port 3000"
