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

外部スキル（show-me / sanitize-artifacts / natural-japanese / yomiyasu）は`install.sh`が元リポジトリを`~/.agents/vendor/`に取得し、両方の配置先から参照させる。
更新したいときは `git pull` して `install.sh` を再実行する。

`natural-japanese` と `yomiyasu` は、`scripts/install-writing.sh` の `NATURAL_REF` と `YOMIYASU_REF` で使用コミットを固定する。更新時は新しい版を確認してからこの値を変更する。原則・文章基準・日本語スキルの配置先に既存ファイルがある場合は、`~/.agents/backups/` に退避してから参照先を切り替える。

## ローカル（Codex / Claude Code 共通）
```
git clone git@github.com:fum1ple/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```
- Codex: 次のターンで `yomiyasu` と `natural-japanese` が使えることを確認。個人指示全体の読み込みは新しいタスクで確認する。呼び出しは `$investigate`
- Claude Code: 再起動して `/investigate` 等が補完に出ることを確認。`~/.claude/CLAUDE.md` に `@~/dotfiles/claude/CLAUDE.md` が追記されている（既存の内容は残る）

指示はこのリポジトリで管理する。`~/.claude/CLAUDE.md`には`claude/CLAUDE.md`の読み込み指定を1行だけ置く。指示本体をホーム側にも書くと、同じファイルを二重に読み込む場合がある。読み込みの経路は次のとおり。

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
                          ├─ ~/.agents/AGENTS.md       ->  agents/AGENTS.md
                          ├─ ~/.agents/principles.md   ->  agents/principles.md
                          └─ ~/.agents/writing.md      ->  agents/writing.md
```

原則・文章基準・日本語スキルだけを配置する場合は、次を実行する。

```bash
bash ~/dotfiles/scripts/install-writing.sh
```

`yomiyasu` は、通常の返答、進捗報告、レビュー、文書、PR本文、コードコメント、コミットメッセージなど、すべての文章出力に適用する。文章の判断基準は `agents/writing.md`、適用条件と優先度は `agents/AGENTS.md`、具体的な推敲手順はスキルに置く。技術用語、コード、引用、指定書式と媒体の文体を保ち、通常の出力に推敲専用の見出しや作業報告は付けない。

Codexでは `$yomiyasu`、Claude Codeでは `/yomiyasu` と明示して使うこともできる。`full` または `--full` の指定時と文章ファイルの保存時は、Python 3で同梱リンターを実行する。診断・採点だけの依頼では対象文章を書き換えない。

`natural-japanese` は明示されたときだけ使い、その対象文章には `yomiyasu` を重ねない。モード未指定は `quick` とする。このスキルの機械検査には `uv` が必要で、実行時にPythonの依存パッケージを取得する。必要なツールが使えなければ目視確認し、機械検査が未実施であることを伝える。

## Codex cloud
1. 対象リポジトリの環境設定 → Setup script に `cloud/codex-setup.sh` の内容を貼る
2. setup script は次を行う
   - dotfilesを取得し、スキルを`~/.agents/skills`に展開
   - `codex/AGENTS.md` を作業リポジトリ直下に `AGENTS.md` としてコピーし、`.git/info/exclude` に登録（コミットもPRにも入らない。リポジトリにAGENTS.mdがある場合は触らない）
3. 動作確認: 新規タスクで「Summarize your current instructions」と投げ、開発原則・文章基準・日本語スキルの適用条件が読まれていることを確認する

## 配置処理の確認

```bash
bash -n install.sh scripts/install-writing.sh
python3 scripts/test-install-writing.py
```

テストは一時ディレクトリを使い、GitHub への通信だけを置き換える。新規配置、既存ファイルの退避、再実行、取得失敗時の既存ファイル保持を確認する。

## 開発フロー
investigate → 承認 → basic-design → 承認 → implement（→ code-review → deliver）
- Codex: `$investigate …`。クラウドではdeliverが`make_pr`でPRを作る
- Claude Code: `/investigate …`。deliverは`gh pr create`でPRを作る
