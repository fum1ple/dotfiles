# dotfiles

Codex 用の個人設定。対象リポジトリには何もコミットしない前提。

```
agents/skills/        → ~/.agents/skills/   自作スキル5本（investigate / basic-design / implement / code-review / deliver）
codex/AGENTS.md       個人の作業指示。ローカルは ~/.codex/AGENTS.md、cloud は作業リポジトリ直下（git 除外）に置かれる
templates/AGENTS.md   リポジトリに AGENTS.md を置いてよい場合の雛形（コマンド・Review guidelines）
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
1. 対象リポジトリの環境設定 → Setup script に `cloud/codex-setup.sh` の内容を貼る
2. setup script は次を行う
   - dotfiles を clone し、スキルを `~/.agents/skills` に展開
   - `codex/AGENTS.md` を作業リポジトリ直下に `AGENTS.md` としてコピーし、`.git/info/exclude` に登録（コミットも PR にも入らない。リポジトリに AGENTS.md がある場合は触らない）
3. 動作確認: 新規タスクで「Summarize your current instructions」と投げ、「$investigate から始める」等が指示に含まれること、`ls ~/.agents/skills` に7本あることを確認する

## 開発フロー
`$investigate` → 承認 → `$basic-design` → 承認 → `$implement`（→ code-review → deliver、PR は make_pr で作成）
