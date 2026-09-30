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
YOMIYASU_REF=30ee6041c328ce21d38a7963f667e079a93d7a12
YOMIYASU_DIR="$VENDOR/yomiyasu-$YOMIYASU_REF"
BACKUP_DIR=""
STAGING_DIR=""

cleanup() {
  if [ -n "$STAGING_DIR" ]; then rm -rf "$STAGING_DIR"; fi
}
trap cleanup EXIT

for rule in AGENTS principles writing; do
  if [ ! -f "$HERE/agents/$rule.md" ]; then
    echo "Missing rule: $HERE/agents/$rule.md" >&2
    exit 1
  fi
done

validate_skill() { # <repository directory> <skill name> <revision>
  local directory="$1" name="$2" revision="$3" file
  if [ "$(git -C "$directory" rev-parse HEAD)" != "$revision" ] || [ ! -f "$directory/skills/$name/SKILL.md" ]; then
    echo "Invalid $name installation: $directory" >&2
    return 1
  fi
  if [ "$name" = yomiyasu ]; then
    for file in LICENSE skills/yomiyasu/scripts/yomiyasu_lint.py skills/yomiyasu/references/gemini-syntax.md \
      skills/yomiyasu/references/domains/tech.md skills/yomiyasu/references/domains/business.md \
      skills/yomiyasu/references/domains/essay.md; do
      if [ ! -f "$directory/$file" ]; then
        echo "Missing yomiyasu resource: $directory/$file" >&2
        return 1
      fi
    done
  fi
}

fetch_pinned_skill() { # <skill name> <repository URL> <revision>
  local name="$1" url="$2" revision="$3" directory
  directory="$VENDOR/$name-$revision"
  if [ ! -e "$directory" ]; then
    STAGING_DIR="$(mktemp -d "$VENDOR/.$name.XXXXXX")"
    git clone --quiet --no-checkout "$url" "$STAGING_DIR"
    git -C "$STAGING_DIR" checkout --quiet --detach "$revision"
    validate_skill "$STAGING_DIR" "$name" "$revision"
    mv "$STAGING_DIR" "$directory"
    STAGING_DIR=""
  else
    validate_skill "$directory" "$name" "$revision"
  fi
}

# 両方の取得・検証が完了してから参照先を切り替える。
mkdir -p "$VENDOR"
fetch_pinned_skill natural-japanese https://github.com/coji/natural-japanese.git "$NATURAL_REF"
fetch_pinned_skill yomiyasu https://github.com/nanaism/yomiyasu.git "$YOMIYASU_REF"

# プラグインの設定を含めず、個人スキルとして同じ上流ファイルを参照する。
if [ ! -e "$YOMIYASU_DIR/agent-skill" ]; then
  STAGING_DIR="$(mktemp -d "$YOMIYASU_DIR/.agent-skill.XXXXXX")"
  for resource in SKILL.md scripts references assets; do
    ln -s "../skills/yomiyasu/$resource" "$STAGING_DIR/$resource"
  done
  ln -s ../LICENSE "$STAGING_DIR/LICENSE"
  mv "$STAGING_DIR" "$YOMIYASU_DIR/agent-skill"
  STAGING_DIR=""
fi
if [ ! -f "$YOMIYASU_DIR/agent-skill/SKILL.md" ] || [ ! -f "$YOMIYASU_DIR/agent-skill/scripts/yomiyasu_lint.py" ] \
  || [ -e "$YOMIYASU_DIR/agent-skill/.claude-plugin" ]; then
  echo "Invalid yomiyasu skill directory: $YOMIYASU_DIR/agent-skill" >&2
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

link_preserving "$HERE/agents/AGENTS.md" "$TARGET_ROOT/.agents/AGENTS.md"
link_preserving "$HERE/agents/principles.md" "$TARGET_ROOT/.agents/principles.md"
link_preserving "$HERE/agents/writing.md" "$TARGET_ROOT/.agents/writing.md"
link_preserving "$NATURAL_DIR/skills/natural-japanese" "$TARGET_ROOT/.agents/skills/natural-japanese"
link_preserving "$NATURAL_DIR/skills/natural-japanese" "$TARGET_ROOT/.claude/skills/natural-japanese"
link_preserving "$YOMIYASU_DIR/agent-skill" "$TARGET_ROOT/.agents/skills/yomiyasu"
link_preserving "$YOMIYASU_DIR/agent-skill" "$TARGET_ROOT/.claude/skills/yomiyasu"
echo "Writing rules, yomiyasu, and natural-japanese installed."
if [ -n "$BACKUP_DIR" ]; then echo "Previous files: $BACKUP_DIR"; fi
