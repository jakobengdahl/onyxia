#!/usr/bin/env bash
set -euo pipefail

cd onyxia/web/
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install yarn
yarn install

#yarn dev --host $(hostname -I | awk '{print $1}') --port 3000
