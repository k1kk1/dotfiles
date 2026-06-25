# Zsh 環境設定 移行仕様書

## 1. 目的

現在の Zsh 環境から、メンテナンス頻度の低い依存を減らし、長期的に保守しやすいシェル設定へ移行する。

主な目的は以下。

* `zinit` を廃止する
* `Powerlevel10k` を廃止する
* 表示内容は大きく変えず、自前 prompt で再現する
* `fzf` は継続利用する
* `z` は `zoxide` で導入する
* CLI ツールは Homebrew 管理へ寄せる
* Zsh plugin は `git clone + source` の単純な方式にする
* kube / aws / terraform / env などの環境表示は残す

## 2. 現状の構成

現在の `.zshrc` は以下の依存を読み込んでいる。

```text
.zshrc
  ├─ ~/.zsh/.zinit.zsh
  ├─ ~/.zsh/.p10k.zsh
  ├─ ~/.zsh/.alias.zsh
  ├─ ~/.fzf.zsh
  ├─ zsh 補完設定
  ├─ history 設定
  ├─ setopt 設定
  └─ PATH 設定
```

Vim / Neovim の設定は旧構成の `.vim/` 配下にまとまっている。
Git 設定は旧構成の `.gitconfig` を継続利用する。

```text
.vim/
  ├─ init.vim
  ├─ dein.toml
  ├─ dein_lazy.toml
  ├─ colors/
  └─ plugins/
```

## 3. 現状の依存関係

### 3.1 zsh 本体

zsh 本体で担っているもの。

* history 管理
* 補完設定
* `auto_cd`
* `auto_pushd`
* `interactive_comments`
* `no_beep`
* `PATH` 設定
* `correct` によるコマンド補正

### 3.2 zinit

zinit で担っているもの。

* zinit 本体のインストール・読み込み
* zinit annex の読み込み
* `zsh-completions`
* `fast-syntax-highlighting`
* `zsh-autosuggestions`
* `history-search-multi-word`
* `fzf-bin`
* `fd`
* `bat`
* `exa`
* `Powerlevel10k` 本体

### 3.3 Powerlevel10k

Powerlevel10k で担っているもの。

* 2行プロンプト
* カレントディレクトリ表示
* Git ブランチ / Git 状態表示
* 直前コマンドの終了ステータス表示
* コマンド実行時間表示
* background jobs 表示
* `direnv` 表示
* `asdf` 表示
* Python / Node / Go / Rust などの環境表示
* `kubecontext`
* `terraform`
* `aws`
* その他多数の右プロンプトセグメント

### 3.4 fzf

fzf で担っているもの。

* `Ctrl-r` による履歴検索
* `Ctrl-t` によるファイル選択
* `Alt-c` によるディレクトリ移動
* `**<Tab>` による fzf 補完

## 4. 移行後の構成

移行後、Zsh 設定は 1 ファイルの `zsh/.zshrc` にまとめる。

```text
zsh/.zshrc
  ├─ 初期設定手順コメント
  ├─ Basic env
  ├─ PATH
  ├─ History
  ├─ Zsh options
  ├─ Plugin paths
  ├─ Completion
  ├─ fzf
  ├─ Plugins
  ├─ Alias
  ├─ Functions
  └─ Prompt
```

Vim / Neovim 設定は旧構成と同じ `.vim/` 配下に置く。
`install.sh` では `.vim/` を `~/.vim` と `~/.config/nvim` へ、`.vim/init.vim` を `~/.vimrc` へリンクする。
Git 設定は `git/.gitconfig` に置き、`~/.gitconfig` へリンクする。
Starship 設定は `starship/starship.toml` に置き、`~/.config/starship.toml` へリンクする。

将来的には、安定後に以下のように分割可能とする。

```text
~/.zshrc
~/.zsh/env.zsh
~/.zsh/path.zsh
~/.zsh/options.zsh
~/.zsh/completion.zsh
~/.zsh/plugins.zsh
~/.zsh/alias.zsh
~/.zsh/functions.zsh
~/.zsh/prompt.zsh
```

## 5. 削除対象

以下は削除予定とする。

### 5.1 zinit

削除する読み込み。

```zsh
[[ ! -f ~/.zsh/.zinit.zsh ]] || source ~/.zsh/.zinit.zsh
```

削除理由。

* plugin 管理、CLI 管理、補完初期化、Powerlevel10k 読み込みが zinit に集中している
* 長期間メンテしない dotfiles では構造が複雑になりやすい
* Homebrew と単純な `source` で代替できる

### 5.2 Powerlevel10k

削除する読み込み。

```zsh
[[ ! -f ~/.zsh/.p10k.zsh ]] || source ~/.zsh/.p10k.zsh
```

削除理由。

* 表示内容は自前 prompt で再現可能
* `.p10k.zsh` が巨大で見通しが悪い
* 使っていない右プロンプトセグメントが多い

### 5.3 history-search-multi-word

削除理由。

* `fzf` の `Ctrl-r` と役割が被る
* 現状の読み込み順では `fzf` 側が優先されている可能性が高い
* 履歴検索は `fzf` に統一する

### 5.4 fast-syntax-highlighting

削除理由。

* zinit 依存を外すため
* 代替として `zsh-users/zsh-syntax-highlighting` を使用する

### 5.5 exa

削除理由。

* `exa` は `eza` へ移行する
* CLI ツールは Homebrew 管理へ寄せる

### 5.6 setopt correct

削除理由。

* コマンド補正の誤爆が起きやすい
* 開発中に確認プロンプトが邪魔になることがある

## 6. 継続利用するもの

### 6.1 zsh 本体設定

以下は継続利用する。

* `SHARE_HISTORY`
* `HIST_IGNORE_ALL_DUPS`
* `HIST_IGNORE_DUPS`
* `HIST_REDUCE_BLANKS`
* `HIST_VERIFY`
* `INC_APPEND_HISTORY`
* `AUTO_CD`
* `AUTO_PUSHD`
* `PUSHD_IGNORE_DUPS`
* `PUSHD_SILENT`
* `LIST_PACKED`
* `AUTO_MENU`
* `COMPLETE_IN_WORD`
* `ALWAYS_TO_END`
* `RM_STAR_WAIT`
* `INTERACTIVE_COMMENTS`
* `PROMPT_SUBST`
* `EXTENDED_GLOB`
* `NO_CASE_GLOB`
* `NO_BEEP`

### 6.2 fzf

fzf は継続利用する。

利用する主なショートカット。

| キー        | 機能       |
| --------- | -------- |
| `Ctrl-r`  | 履歴検索     |
| `Ctrl-t`  | ファイル選択   |
| `Alt-c`   | ディレクトリ移動 |
| `**<Tab>` | fzf 補完   |

### 6.3 zsh-autosuggestions

履歴ベースの入力補完として継続利用する。

### 6.4 zsh-syntax-highlighting

入力中のコマンド色分けとして継続利用する。

### 6.5 zsh-completions

追加補完として継続利用する。

ただし、必須ではない。不要であれば削除可能。

## 7. CLI ツール管理方針

CLI ツールは zinit ではなく Homebrew で管理する。

導入対象。

```sh
brew install fzf fd bat eza ripgrep jq yq direnv
```

### 7.1 eza

`exa` の代替として使用する。

alias。

```zsh
alias l='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias tree='eza --tree --icons --group-directories-first'
```

### 7.2 fzf

fzf 本体は Homebrew で管理する。

shell integration は以下を読み込む。

```zsh
$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh
$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh
```

既存互換として `~/.fzf.zsh` も読み込む。

## 8. Zsh plugin 管理方針

zinit は使わず、GitHub から clone したものを直接 source する。

インストール先。

```text
~/.local/share/zsh/plugins
```

対象 plugin。

```text
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
```

初期 clone 手順。

```sh
mkdir -p ~/.local/share/zsh/plugins

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  ~/.local/share/zsh/plugins/zsh-autosuggestions

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  ~/.local/share/zsh/plugins/zsh-syntax-highlighting

git clone --depth=1 https://github.com/zsh-users/zsh-completions \
  ~/.local/share/zsh/plugins/zsh-completions
```

更新用関数。

```zsh
zsh-plugins-update
```

## 9. プロンプト仕様

Powerlevel10k を使わず、自前 prompt を使用する。

### 9.1 左プロンプト

左プロンプトは2行構成。

```text
<current directory> <git branch/status>
❯
```

例。

```text
~/src/my-app  feature/foo*
❯
```

### 9.2 右プロンプト

右プロンプトには、必要な環境情報のみ表示する。

表示対象。

* 直前コマンドの終了ステータス
* コマンド実行時間
* `direnv`
* `asdf`
* Python 仮想環境
* conda 環境
* pyenv version
* Node 環境
* kube context
* Terraform workspace
* AWS profile
* AWS Vault

### 9.3 Git 表示

Git repository 内では以下を表示する。

```text
 <branch>
```

dirty 状態の場合は `*` を付ける。

```text
 feature/foo*
```

### 9.4 終了ステータス表示

直前コマンドが失敗した場合のみ表示する。

```text
✘ 1
```

### 9.5 実行時間表示

3秒以上かかったコマンドのみ表示する。

```text
8s
```

### 9.6 kube context 表示

`kubectl` が存在し、`KUBECONFIG` または `~/.kube/config` がある場合のみ表示する。

通常。

```text
k8s:dev
```

staging 系。

```text
k8s:staging
```

production 系。

```text
⛔ k8s:production
```

kube context は毎回 `kubectl` を実行しないよう、5秒キャッシュする。

### 9.7 Terraform 表示

以下のいずれかがある場合のみ表示する。

* `.terraform/environment`
* `.terraform/`
* `TF_WORKSPACE`

表示例。

```text
tf:default
```

### 9.8 AWS 表示

以下を表示する。

```text
aws:<AWS_PROFILE>
aws-vault:<AWS_VAULT>
```

## 10. 補完仕様

補完は zsh 標準の `compinit` を使用する。

Homebrew の補完関数と `zsh-completions` が存在する場合は、`compinit` より前に `fpath` へ追加する。

補完設定。

```zsh
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{244}-- %d --%f'
```

`.zcompdump` が存在し、24時間以内に更新されている場合は `compinit -C` を使って高速化する。
`.zcompdump` が無い、または古い場合は通常の `compinit` で補完キャッシュを作り直す。

## 11. History 仕様

履歴設定。

```zsh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
```

履歴オプション。

```zsh
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
```

## 12. PATH 仕様

`typeset -U path PATH` により PATH の重複を防ぐ。

優先順。

```text
~/.local/bin
~/bin
/opt/homebrew/bin
/opt/homebrew/sbin
/usr/local/bin
/usr/local/sbin
/usr/bin
/bin
/usr/sbin
/sbin
既存 PATH
```

## 13. Alias 仕様

### 13.1 eza

```zsh
alias l='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias tree='eza --tree --icons --group-directories-first'
```

### 13.2 Git

```zsh
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all -30'
alias gp='git push'
alias gpl='git pull --ff-only'
```

### 13.3 Infra

```zsh
alias k='kubectl'
alias tf='terraform'
```

## 14. Functions 仕様

### 14.1 mkcd

ディレクトリを作成して移動する。

```zsh
mkcd <dir>
```

### 14.2 reload-zsh

`.zshrc` を再読み込みする。

```zsh
reload-zsh
```

### 14.3 path-list

PATH を1行ずつ表示する。

```zsh
path-list
```

### 14.4 which-all

指定コマンドの解決先をすべて表示する。

```zsh
which-all <command>
```

### 14.5 zsh-startup-time

zsh の起動時間を5回測定する。

```zsh
zsh-startup-time
```

### 14.6 zsh-plugins-update

`~/.local/share/zsh/plugins` 配下の Git repository を更新する。

```zsh
zsh-plugins-update
```

## 15. 初期設定手順

### 15.1 バックアップ

```sh
cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d%H%M%S)
cp ~/.zsh/.zinit.zsh ~/.zsh/.zinit.zsh.backup 2>/dev/null || true
cp ~/.zsh/.p10k.zsh ~/.zsh/.p10k.zsh.backup 2>/dev/null || true
```

### 15.2 Homebrew ツール導入

```sh
brew install fzf fd bat eza ripgrep jq yq direnv
```

### 15.3 Zsh plugin 導入

```sh
mkdir -p ~/.local/share/zsh/plugins

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  ~/.local/share/zsh/plugins/zsh-autosuggestions

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  ~/.local/share/zsh/plugins/zsh-syntax-highlighting

git clone --depth=1 https://github.com/zsh-users/zsh-completions \
  ~/.local/share/zsh/plugins/zsh-completions
```

### 15.4 `.zshrc` 置き換え

完成版 `.zshrc` を `~/.zshrc` に保存する。

### 15.5 読み込み

```sh
source ~/.zshrc
```

### 15.6 動作確認

fzf 履歴検索。

```sh
bindkey '^R'
```

期待値。

```text
"^R" fzf-history-widget
```

PATH 確認。

```sh
path-list
```

起動時間確認。

```sh
zsh-startup-time
```

Git 表示確認。

```sh
cd <git repository>
```

kube context 確認。

```sh
kubectl config current-context
```

## 16. ショートカット仕様

### 16.1 zsh

| キー       | 機能           |
| -------- | ------------ |
| `Tab`    | 補完           |
| `Ctrl-c` | 中断           |
| `Ctrl-d` | EOF / シェル終了  |
| `Ctrl-l` | 画面クリア        |
| `Ctrl-a` | 行頭へ移動        |
| `Ctrl-e` | 行末へ移動        |
| `Ctrl-u` | 行頭まで削除       |
| `Ctrl-k` | 行末まで削除       |
| `Ctrl-w` | 直前の単語を削除     |
| `Ctrl-y` | 削除した文字列を貼り付け |
| `Ctrl-_` | Undo         |

### 16.2 fzf

| キー        | 機能       |
| --------- | -------- |
| `Ctrl-r`  | 履歴検索     |
| `Ctrl-t`  | ファイル選択   |
| `Alt-c`   | ディレクトリ移動 |
| `**<Tab>` | fzf 補完   |

### 16.3 zsh-autosuggestions

| キー      | 機能       |
| ------- | -------- |
| `→`     | 候補を受け入れる |
| `End`   | 候補を受け入れる |
| `Alt-f` | 1単語分進む   |

## 17. ロールバック手順

問題が起きた場合はバックアップへ戻す。

```sh
cp ~/.zshrc.backup.YYYYMMDDHHMMSS ~/.zshrc
source ~/.zshrc
```

zinit / Powerlevel10k 設定ファイル自体は削除せず、しばらく残す。

```text
~/.zsh/.zinit.zsh
~/.zsh/.p10k.zsh
```

## 18. 将来の分割方針

1ファイル版で安定した後、以下に分割する。

```text
~/.zshrc
~/.zsh/env.zsh
~/.zsh/path.zsh
~/.zsh/options.zsh
~/.zsh/completion.zsh
~/.zsh/plugins.zsh
~/.zsh/alias.zsh
~/.zsh/functions.zsh
~/.zsh/prompt.zsh
```

`.zshrc` は読み込みだけにする。

```zsh
for file in \
  "$HOME/.zsh/env.zsh" \
  "$HOME/.zsh/path.zsh" \
  "$HOME/.zsh/options.zsh" \
  "$HOME/.zsh/completion.zsh" \
  "$HOME/.zsh/plugins.zsh" \
  "$HOME/.zsh/alias.zsh" \
  "$HOME/.zsh/functions.zsh" \
  "$HOME/.zsh/prompt.zsh"
do
  [[ -r "$file" ]] && source "$file"
done
```

## 19. 完了条件

以下を満たせば移行完了とする。

* 新しい `.zshrc` で zsh が起動する
* `zinit` を読み込んでいない
* `Powerlevel10k` を読み込んでいない
* `Ctrl-r` で fzf 履歴検索が動く
* Git repository でブランチ名が表示される
* dirty 状態で `*` が表示される
* kube context が表示される
* production 系 kube context が赤く警告表示される
* `aws` / `terraform` / `direnv` の表示が必要時に出る
* `zsh-startup-time` で起動時間を確認できる
* 既存 alias が読み込まれる
* PATH が重複しない
