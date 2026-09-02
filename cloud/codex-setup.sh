#!/bin/bash
# Codex cloud 環境の Setup script に貼る内容
# clone 直後に作業リポジトリのディレクトリで実行される前提
set -euo pipefail
REPO_URL="https://github.com/fum1ple/dotfiles.git"

# 1. dotfiles を取得して展開（スキル → ~/.agents/skills、指示 → ~/.codex/AGENTS.md）
if [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only -q || true
else
  git clone --depth 1 -q "$REPO_URL" "$HOME/dotfiles"
fi
bash "$HOME/dotfiles/install.sh"

# 2. 作業リポジトリ直下に AGENTS.md を置く（コミットしない）
#    .git/info/exclude に登録するので git status にも git add -A にも現れない
#    リポジトリ側に AGENTS.md がある場合は上書きしない
if [ -d .git ] && [ ! -e AGENTS.md ]; then
  cp "$HOME/dotfiles/codex/AGENTS.md" ./AGENTS.md
  mkdir -p .git/info
  grep -qx 'AGENTS.md' .git/info/exclude 2>/dev/null || echo 'AGENTS.md' >> .git/info/exclude
fi

# 3. 動作確認用の出力（環境のセットアップログで見える）
echo "skills:"; ls -1 "$HOME/.agents/skills" || true
echo "AGENTS.md in repo: $([ -e AGENTS.md ] && echo yes || echo no)"
exit 0
