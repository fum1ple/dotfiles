#!/bin/bash
# 開発原則・文章基準・日本語スキルを Codex と Claude Code に配置する。
# 第1引数で配置先を指定できる。省略時は現在のユーザーに配置する。
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_ROOT="${1:-$HOME}"
mkdir -p "$TARGET_ROOT"
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"
VENDOR="$TARGET_ROOT/.agents/vendor"
NATURAL_REF=9a78a42964096da509b8f3e011f0085a5f080151
NATURAL_DIR="$VENDOR/natural-japanese-$NATURAL_REF"
BACKUP_DIR=""
STAGING_DIR=""

cleanup() {
  if [ -n "$STAGING_DIR" ]; then rm -rf "$STAGING_DIR"; fi
}
trap cleanup EXIT

for rule in principles writing; do
  if [ ! -f "$HERE/agents/$rule.md" ]; then
    echo "Missing rule: $HERE/agents/$rule.md" >&2
    exit 1
  fi
done

# 取得が完了してから参照先を切り替える。
mkdir -p "$VENDOR"
if [ ! -e "$NATURAL_DIR" ]; then
  STAGING_DIR="$(mktemp -d "$VENDOR/.natural-japanese.XXXXXX")"
  git clone --quiet --no-checkout https://github.com/coji/natural-japanese.git "$STAGING_DIR"
  git -C "$STAGING_DIR" checkout --quiet --detach "$NATURAL_REF"
  mv "$STAGING_DIR" "$NATURAL_DIR"
  STAGING_DIR=""
fi
if [ "$(git -C "$NATURAL_DIR" rev-parse HEAD)" != "$NATURAL_REF" ] || [ ! -f "$NATURAL_DIR/skills/natural-japanese/SKILL.md" ]; then
  echo "Invalid natural-japanese installation: $NATURAL_DIR" >&2
  exit 1
fi

link_preserving() { # <source> <destination>
  local source="$1" destination="$2" backup
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    return
  fi
  mkdir -p "$(dirname "$destination")"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ -z "$BACKUP_DIR" ]; then
      mkdir -p "$TARGET_ROOT/.agents/backups"
      BACKUP_DIR="$(mktemp -d "$TARGET_ROOT/.agents/backups/writing.XXXXXX")"
    fi
    backup="$BACKUP_DIR/${destination#"$TARGET_ROOT/"}"
    mkdir -p "$(dirname "$backup")"
    mv "$destination" "$backup"
  fi
  ln -s "$source" "$destination"
}

link_preserving "$HERE/agents/principles.md" "$TARGET_ROOT/.agents/principles.md"
link_preserving "$HERE/agents/writing.md" "$TARGET_ROOT/.agents/writing.md"
link_preserving "$NATURAL_DIR/skills/natural-japanese" "$TARGET_ROOT/.agents/skills/natural-japanese"
link_preserving "$NATURAL_DIR/skills/natural-japanese" "$TARGET_ROOT/.claude/skills/natural-japanese"
echo "Writing rules and natural-japanese installed."
if [ -n "$BACKUP_DIR" ]; then echo "Previous files: $BACKUP_DIR"; fi
