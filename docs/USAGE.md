# dotfiles 使い方ガイド

## ファイル構成

```text
dotfiles/
├── install.sh          セットアップスクリプト（冪等）
├── zsh/
│   └── .zshrc          Zsh 設定 -> ~/.zshrc
├── git/
│   └── .gitconfig      Git 設定 -> ~/.gitconfig
├── starship/
│   └── starship.toml   プロンプト設定 -> ~/.config/starship.toml
├── vim/                Vim / Neovim 設定 -> ~/.vim, ~/.config/nvim
├── ghostty/
│   └── config          ターミナル設定 -> ~/.config/ghostty/config
├── tmux/
│   └── .tmux.conf      tmux設定 -> ~/.tmux.conf
└── docs/
    ├── SPEC.md         移行仕様書
    ├── USAGE.md        このファイル
    └── cheatsheet.html キーボード・設定チートシート
```

---

## セットアップ

```zsh
zsh install.sh
source ~/.zshrc
```

install.sh は以下を自動実行する。何度実行しても安全（冪等）。

1. Homebrew ツールのインストール（未インストールのみ）
2. Zsh プラグインの clone（未 clone のみ）
3. シンボリックリンクの作成（`~/.zshrc`, `~/.gitconfig`, `~/.config/starship.toml`, `~/.config/ghostty/config`, `~/.tmux.conf`, `~/.vim`, `~/.vimrc`, `~/.config/nvim`）
4. 構文チェックと fzf 動作確認

---

## プロンプト表示

### 左プロンプト

```text
~/src/my-app   feature/login*1⇡1
❯
```

| 要素 | 説明 |
| --- |---|
| `~/src/my-app` | 現在ディレクトリ（5階層以上は `…/` 省略） |
| `読み取り専用 󰌾` | 書き込み不可ディレクトリ |
| ` feature/login` | Git ブランチ名（赤） |
| `*1` | 変更あり（modified） |
| `+1` | ステージ済み（staged） |
| `?1` | 未追跡ファイル（untracked） |
| `⇡1` | リモートより N コミット先行 |
| `⇣1` | リモートより N コミット遅れ |
| `~1` | コンフリクトあり |
| `❯`（白） | 直前コマンド成功 |
| `❯`（赤） | 直前コマンド失敗 |
| `❮` | Vim ノーマルモード |

### 右プロンプト

| 表示 | 色 | 条件 |
| --- |---| --- |
| `✘ 1` | 赤 | 直前コマンドが失敗（終了コード） |
| `12s` | グレー | コマンドが 3 秒以上かかった |
| `⚙ 2` | シアン | バックグラウンドジョブが動いている |
| ` v3.11.9 (.venv)` | シアン | `python3 -m venv` の仮想環境が有効 |
| ` v20.0.0` | グレー | Node.js（package.json があるとき） |
| `󱃾 my-dev` | 紫 | Kubernetes context |
| `󱃾 my-staging` | 黄 | staging 系 context |
| `⛔ my-production` | 赤太字 | prod / production 系 context |

---

## キーバインド

### fzf

| キー | 動作 |
| --- |---|
| `Ctrl-r` | 履歴をインクリメンタル検索 |
| `Ctrl-t` | カレントディレクトリ以下のファイルを選択 |
| `Alt-c` | ディレクトリをインタラクティブに移動 |
| `**<Tab>` | fzf で補完 |

### zsh-autosuggestions

| キー | 動作 |
| --- |---|
| `→` / `End` | 候補を全部受け入れる |
| `Alt-f` | 候補を 1 単語分受け入れる |

### Zsh 標準

| キー | 動作 |
| --- |---|
| `Tab` | 補完（メニュー選択式） |
| `Ctrl-r` | 履歴検索（fzf に上書き） |
| `Ctrl-a` / `Ctrl-e` | 行頭 / 行末へ移動 |
| `Ctrl-u` / `Ctrl-k` | 行頭まで / 行末まで削除 |
| `Ctrl-w` | 直前の単語を削除 |
| `Ctrl-y` | 削除した文字列を貼り付け |
| `Ctrl-_` | Undo |

---

## エイリアス

### ファイル操作（eza）

| コマンド | 実行内容 |
| --- |---|
| `l` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first --git` |
| `la` | `eza -a --icons --group-directories-first` |
| `tree` | `eza --tree --icons --group-directories-first` |
| `cat` | `bat`（旧設定 `~/.zsh/.alias.zsh` より） |
| `ls` | `eza`（旧設定より） |
| `grep` | `rg`（旧設定より） |

### Git

| コマンド | 実行内容 |
| --- |---|
| `g` | `git` |
| `gs` | `git status --short --branch` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gd` | `git diff` |
| `gl` | `git log --oneline --graph --decorate --all -30` |
| `gp` | `git push` |
| `gpl` | `git pull --ff-only` |

### インフラ

| コマンド | 実行内容 |
| --- |---|
| `k` | `kubectl` |
| `tf` | `terraform` |

---

## 関数

| コマンド | 動作 |
| --- |---|
| `mkcd <dir>` | ディレクトリを作成して移動 |
| `reload-zsh` | `.zshrc` を再読み込み |
| `path-list` | PATH を 1 行ずつ表示 |
| `which-all <cmd>` | コマンドの解決先をすべて表示 |
| `zsh-startup-time` | シェル起動時間を 5 回測定 |
| `zsh-plugins-update` | Zsh プラグインを一括 `git pull` |

---

## ディレクトリ移動（z）

`zoxide` を使って、履歴ベースでディレクトリへ移動する。

| コマンド | 動作 |
| --- |---|
| `z <keyword>` | 過去に移動したディレクトリから一致する場所へ移動 |
| `zi` | fzf で候補を選んで移動 |

---

## Zsh プラグイン

インストール先: `~/.local/share/zsh/plugins/`

| プラグイン | 効果 |
| --- |---|
| `zsh-autosuggestions` | 履歴ベースの入力候補をグレーで表示 |
| `zsh-syntax-highlighting` | 入力中のコマンドをリアルタイム色分け |
| `zsh-completions` | 追加の補完定義 |

更新:

```zsh
zsh-plugins-update
```

---

## Homebrew ツール

| ツール | 用途 |
| --- |---|
| `fzf` | ファジーファインダー |
| `fd` | 高速 `find` 代替 |
| `bat` | シンタックスハイライト付き `cat` 代替 |
| `eza` | アイコン付き `ls` 代替 |
| `ripgrep` | 高速 `grep` 代替 |
| `jq` | JSON 処理 |
| `yq` | YAML 処理 |
| `direnv` | ディレクトリごとの環境変数管理 |
| `zoxide` | 履歴ベースの高速ディレクトリ移動（`z`） |
| `starship` | プロンプト |

---

## Kubernetes context の確認

```zsh
# 現在の context 表示
kubectl config current-context

# context 一覧
kubectl config get-contexts

# context 切り替え（右プロンプトに反映される）
kubectl config use-context <context-name>
```

prod / production を含む context 名は右プロンプトに `⛔` が赤で表示される。

---

## Ghostty 設定

| 設定 | 値 |
| --- |---|
| フォント | HackGen Console NF（Nerd Font 対応） |
| フォントサイズ | 12pt |
| 背景色 | `#0b0b0b`（ディープブラック） |
| 背景透過 | 85% |
| タイトルバー | 非表示 |

設定変更後は `Cmd+Shift+,` で再読み込み。
