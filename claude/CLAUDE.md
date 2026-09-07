# 個人設定（~/.claude/CLAUDE.md から import される）

**全てのエージェントは日本語で応答します。**

- 以下の指示で `$name` と書かれているものはスキル名。Claude Code では `/name` で呼び出す（例: `$investigate` → `/investigate`）
- `make_pr` ツールは Codex cloud 専用。Claude Code では `gh pr create` で PR を作る

@~/.agents/AGENTS.md
@~/dotfiles/codex/AGENTS.md
@~/.agents/principles.md
@~/.agents/writing.md

## 並列開発環境（git worktree + Worktrunk）

複数ブランチをポート競合・DB競合なしで同時に起動できる環境。

### セットアップ済み内容（doc_automate リポジトリ）

- `docker-compose.yml`: ポート・DB名を環境変数化（`${API_PORT:-3002}` 等）
- `api/config/database.yml`: `DB_NAME` 環境変数で論理DB分離
- `~/.config/worktrunk/config.toml`: worktree作成時に `.envrc` を自動コピー
- `~/worktrees/` 配下に worktree を整理

### 新しい worktree の立ち上げ方

```bash
# 1. worktree 作成（.envrc が自動コピーされる）
wt switch -c feature/OA-XXXX/description

# 2. Claude Code でセットアップ（ポート計算・DB作成・マイグレーション）
/worktree-setup
```

### worktree の削除

```bash
git worktree remove ~/worktrees/doc_automate/<branch>
docker compose -p doc_automate_<branch> down -v
```

### ポート割り当て規則

| サービス | メイン環境 | worktree |
|---------|-----------|---------|
| API | 3002 | 3100〜3999（ブランチ名ハッシュ） |
| Front | 8001 | 8100〜8999 |
| DB | 5433 | 5600〜6499 |
