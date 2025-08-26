#!/usr/bin/env bash
set -euo pipefail

# Använd sudo om det finns, annars kör som root
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# Säkerställ apt och installera npm (drar in nodejs som beroende)
$SUDO apt-get update -y
DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y npm

# Installera yarn globalt via npm (klassisk Yarn 1.x)
$SUDO npm install -g yarn

# Fortsätt med projektet
cd onyxia/web/
yarn install

# Start (valfritt): exponera på containerns IP och port 3000
# yarn dev --host "$(hostname -I | awk '{print $1}')" --port 3000
