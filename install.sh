#!/bin/bash
# このリポジトリの内容をホームディレクトリに展開する（symlink 方式）
# 使い方: git clone <this repo> ~/dotfiles && ~/dotfiles/install.sh
# 何度実行しても同じ結果になる。更新は git pull してから再実行。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
VENDOR="$HOME/.agents/vendor"

mkdir -p "$HOME/.agents/skills" "$VENDOR" "$HOME/.codex"

# 1. 自作スキル: agents/skills/<name> → ~/.agents/skills/<name>
for d in "$HERE"/agents/skills/*/; do
  ln -sfn "$d" "$HOME/.agents/skills/$(basename "$d")"
done

# 2. 外部スキル: 元リポを ~/.agents/vendor に clone し、該当ディレクトリだけ symlink
fetch() { # <git url> <dir>
  if [ -d "$2/.git" ]; then git -C "$2" pull --ff-only -q || true
  else git clone --depth 1 -q "$1" "$2"; fi
}
fetch https://github.com/humanlayer/skills.git "$VENDOR/humanlayer-skills"
fetch https://github.com/kotek-7/dotfiles.git "$VENDOR/kotek-7-dotfiles"
ln -sfn "$VENDOR/humanlayer-skills/plugins/show-me/skills/show-me"            "$HOME/.agents/skills/show-me"
ln -sfn "$VENDOR/kotek-7-dotfiles/dot_agents/skills/sanitize-artifacts"       "$HOME/.agents/skills/sanitize-artifacts"

# 3. Codex のグローバル指示
ln -sfn "$HERE/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

echo "installed skills:"; ls -1 "$HOME/.agents/skills"
