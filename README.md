# dotfiles

Codex と Claude Code で共通に使う個人設定。対象リポジトリには何もコミットしない前提。

```
agents/skills/        自作スキル5本（investigate / basic-design / implement / code-review / deliver）
                      → ~/.agents/skills/（Codex）と ~/.claude/skills/（Claude Code）の両方に symlink
agents/AGENTS.md      Codex / Claude Code 共通の作業指示 → ~/.agents/AGENTS.md
agents/principles.md  開発上の判断基準 → ~/.agents/principles.md
agents/writing.md     文章の構成・日本語・レビュー文体 → ~/.agents/writing.md
codex/AGENTS.md       個人の作業指示。Codex ローカルは ~/.codex/AGENTS.md、cloud は作業リポジトリ直下（git 除外）
claude/CLAUDE.md      Claude Code 用の設定本体。~/.claude/CLAUDE.md から import され、共通指示・原則・文章基準を読み込む
templates/AGENTS.md   リポジトリに AGENTS.md を置いてよい場合の雛形（コマンド・Review guidelines）
cloud/codex-setup.sh  Codex cloud 環境の Setup script
install.sh            展開スクリプト
scripts/install-writing.sh  原則・文章基準・日本語スキルの配置
```

外部スキル（show-me / sanitize-artifacts / natural-japanese）は install.sh が元リポジトリを `~/.agents/vendor/` に clone して両方に symlink する。
更新したいときは `git pull` して `install.sh` を再実行する。

`natural-japanese` は `scripts/install-writing.sh` の `NATURAL_REF` で使用コミットを固定する。更新時は新しい版を確認してからこの値を変更する。原則・文章基準・日本語スキルの配置先に既存ファイルがある場合は、`~/.agents/backups/` に退避してから参照先を切り替える。

## ローカル（Codex / Claude Code 共通）
```
git clone git@github.com:fum1ple/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```
- Codex: 次のターンで `natural-japanese` が使えることを確認。個人指示全体の読み込みは新しいタスクで確認する。呼び出しは `$investigate`
- Claude Code: 再起動して `/investigate` 等が補完に出ることを確認。`~/.claude/CLAUDE.md` に `@~/dotfiles/claude/CLAUDE.md` が追記されている（既存の内容は残る）

指示の正本はこのリポジトリに置く。`~/.claude/CLAUDE.md` は `claude/CLAUDE.md` への import 1 行だけにして、指示そのものは書かない。ホーム側に直接書くと、同じファイルを 2 経路から import して二重に読み込む状態になりやすい。読み込みの経路は次のとおり。

```
@ = import 行   -> = symlink

Claude Code
  ~/.claude/CLAUDE.md  @  claude/CLAUDE.md
                          ├─ @ ~/.agents/AGENTS.md      ->  agents/AGENTS.md
                          ├─ @ ~/dotfiles/codex/AGENTS.md
                          ├─ @ ~/.agents/principles.md  ->  agents/principles.md
                          └─ @ ~/.agents/writing.md     ->  agents/writing.md

Codex
  ~/.codex/AGENTS.md   ->  codex/AGENTS.md
```

原則・文章基準・日本語スキルだけを配置する場合:

```bash
bash ~/dotfiles/scripts/install-writing.sh
```

普段の返答と短いレビューコメントは文章基準で書く。調査報告・PR 本文・社内文書などの執筆やまとまった改稿は `natural-japanese` の `quick` を使い、`full` は明示したときに使う。具体的な適用条件は `codex/AGENTS.md` に置く。機械検査には `uv` が必要で、実行時に Python の依存パッケージを取得する。`uv` が使えない環境ではスキルの手動チェックを使う。

## Codex cloud
1. 対象リポジトリの環境設定 → Setup script に `cloud/codex-setup.sh` の内容を貼る
2. setup script は次を行う
   - dotfiles を clone し、スキルを `~/.agents/skills` に展開
   - `codex/AGENTS.md` を作業リポジトリ直下に `AGENTS.md` としてコピーし、`.git/info/exclude` に登録（コミットも PR にも入らない。リポジトリに AGENTS.md がある場合は触らない）
3. 動作確認: 新規タスクで「Summarize your current instructions」と投げ、開発原則・文章基準・日本語スキルの適用条件が読まれていることを確認する

## 配置処理の確認

```bash
bash -n install.sh scripts/install-writing.sh
python3 scripts/test-install-writing.py
```

テストは一時ディレクトリを使い、GitHub への通信だけを置き換える。新規配置、既存ファイルの退避、再実行、取得失敗時の既存ファイル保持を確認する。

## 開発フロー
investigate → 承認 → basic-design → 承認 → implement（→ code-review → deliver）
- Codex: `$investigate …`。cloud では deliver が `make_pr` で PR を作る
- Claude Code: `/investigate …`。deliver は `gh pr create` で PR を作る
