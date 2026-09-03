#!/bin/bash
# このリポジトリの内容をホームディレクトリに展開する（symlink 方式）
# 使い方: git clone <this repo> ~/dotfiles && bash ~/dotfiles/install.sh
# 何度実行しても同じ結果になる。更新は git pull してから再実行。
# 対象: Codex（~/.agents/skills, ~/.codex）と Claude Code（~/.claude/skills, ~/.claude/CLAUDE.md）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
VENDOR="$HOME/.agents/vendor"

mkdir -p "$HOME/.agents/skills" "$VENDOR" "$HOME/.codex" "$HOME/.claude/skills"

# 1. 外部スキルの元リポを ~/.agents/vendor に取得
fetch() { # <git url> <dir>
  if [ -d "$2/.git" ]; then git -C "$2" pull --ff-only -q || true
  else git clone --depth 1 -q "$1" "$2"; fi
}
fetch https://github.com/humanlayer/skills.git "$VENDOR/humanlayer-skills"
fetch https://github.com/kotek-7/dotfiles.git "$VENDOR/kotek-7-dotfiles"

# 2. スキルを Codex と Claude Code の両方に symlink
link_skill() { # <src dir> <name>
  ln -sfn "$1" "$HOME/.agents/skills/$2"
  ln -sfn "$1" "$HOME/.claude/skills/$2"
}
for d in "$HERE"/agents/skills/*/; do
  link_skill "${d%/}" "$(basename "$d")"
done
link_skill "$VENDOR/humanlayer-skills/plugins/show-me/skills/show-me"        show-me
link_skill "$VENDOR/kotek-7-dotfiles/dot_agents/skills/sanitize-artifacts"   sanitize-artifacts

# 3. 個人の作業指示
#    Codex: ~/.codex/AGENTS.md を symlink
#    Claude Code: ~/.claude/CLAUDE.md に import 行を追記（既存の内容は残す）
ln -sfn "$HERE/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
IMPORT_LINE="@$HERE/claude/CLAUDE.md"
touch "$HOME/.claude/CLAUDE.md"
grep -qxF "$IMPORT_LINE" "$HOME/.claude/CLAUDE.md" || printf '\n%s\n' "$IMPORT_LINE" >> "$HOME/.claude/CLAUDE.md"

echo "Codex skills (~/.agents/skills):";  ls -1 "$HOME/.agents/skills"
echo "Claude Code skills (~/.claude/skills):"; ls -1 "$HOME/.claude/skills"
