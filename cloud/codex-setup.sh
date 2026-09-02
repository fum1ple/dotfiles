#!/bin/bash
# Codex cloud 環境の Setup script に貼る内容
set -euo pipefail
REPO_URL="https://github.com/fum1ple/dotfiles.git"

if [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only -q || true
else
  git clone --depth 1 -q "$REPO_URL" "$HOME/dotfiles"
fi
bash "$HOME/dotfiles/install.sh"
exit 0
