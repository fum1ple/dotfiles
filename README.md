# dotfiles

Codex 用の個人設定。`install.sh` がホームディレクトリに symlink を張る。

```
agents/skills/        → ~/.agents/skills/   自作スキル5本（investigate / basic-design / implement / code-review / deliver）
codex/AGENTS.md       → ~/.codex/AGENTS.md  個人のグローバル指示
templates/AGENTS.md   対象リポジトリのルートに置く雛形（Review guidelines・コマンド）
cloud/codex-setup.sh  Codex cloud 環境の Setup script
install.sh            展開スクリプト
```

外部スキル（show-me / sanitize-artifacts）は install.sh が元リポジトリを `~/.agents/vendor/` に clone して symlink する。
更新したいときは `install.sh` を再実行する。

## ローカル
```
git clone git@github.com:fum1ple/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```
Codex を再起動し、`/skills` で5本＋2本が見えることを確認する。

## Codex cloud
1. Codex の環境設定 → Setup script に `cloud/codex-setup.sh` の内容を貼る
2. 初回タスクで「Summarize your current instructions」と投げ、`~/.codex/AGENTS.md` の内容が返るか確認する。返らなければ、その内容は各リポの AGENTS.md 側に移す

## 開発フロー
`$investigate` → 承認 → `$basic-design` → 承認 → `$implement`（→ code-review → deliver）→ Create PR
対象リポジトリには `templates/AGENTS.md` を置き、「コマンド」節を書き換える。
