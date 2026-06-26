# ~/.zshrc
#
# ==============================================================================
# 方針
# ==============================================================================
#
# - zinit は使わない
# - Powerlevel10k は使わない (Starship に移行)
# - fzf は残す
# - CLI ツールは Homebrew で管理する
# - Zsh plugin は git clone + source で管理する
# - env / kube / terraform / aws などの右プロンプトは Starship で表示
#
# ==============================================================================
# 初期設定手順
# ==============================================================================
#
# 1. 既存設定をバックアップ
#
#   cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d%H%M%S)
#
# 2. install.sh を実行
#
#   zsh install.sh
#
# 3. 読み込み直す
#
#   source ~/.zshrc
#
# ==============================================================================
# Basic env
# ==============================================================================

export LANG="ja_JP.UTF-8"
export EDITOR="vim"
export VISUAL="$EDITOR"
export PAGER="less"

# ==============================================================================
# PATH
# ==============================================================================

# PATH の重複を自動で排除する
typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/bin"

  # Apple Silicon Homebrew
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"

  # Intel Mac / common local paths
  "/usr/local/bin"
  "/usr/local/sbin"

  # system
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"

  $path
)

export PATH

# ==============================================================================
# History
# ==============================================================================

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY

# ==============================================================================
# Zsh options
# ==============================================================================

# Directory
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
setopt LIST_PACKED
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# Safety
setopt RM_STAR_WAIT

# Comments
setopt INTERACTIVE_COMMENTS

# Glob
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB

# Beep
setopt NO_BEEP

# ==============================================================================
# Key bindings
# ==============================================================================

# EDITOR=vim の影響で vi キーマップになる環境でも、端末操作は Emacs 風に固定する
bindkey -e

# ==============================================================================
# Plugin paths
# ==============================================================================

ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# Homebrew の補完関数を compinit より前に fpath へ追加する
if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"
  if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
  fi
fi

# zsh-completions は compinit より前に fpath へ追加する
if [[ -d "$ZSH_PLUGIN_DIR/zsh-completions/src" ]]; then
  fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
fi

# ==============================================================================
# Completion
# ==============================================================================

autoload -Uz compinit

zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

# .zcompdump が無い、または古いときは通常 compinit、それ以外は -C で高速起動
if [[ ! -f "$zcompdump" || -n "$zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{244}-- %d --%f'

# ==============================================================================
# fzf
# ==============================================================================

# Homebrew fzf を優先
if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"

  [[ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]] &&
    source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"

  [[ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]] &&
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
fi

[[ -r "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# ==============================================================================
# Plugins
# ==============================================================================

_source_if_exists() {
  local file="$1"
  [[ -r "$file" ]] && source "$file"
}

_source_if_exists "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# syntax-highlighting は最後に読み込む
_source_if_exists "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ==============================================================================
# Alias
# ==============================================================================

[[ -r "$HOME/.zsh/.alias.zsh" ]] && source "$HOME/.zsh/.alias.zsh"

# eza
if command -v eza >/dev/null 2>&1; then
  alias l='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias tree='eza --tree --icons --group-directories-first'
fi

alias grep='grep --color=auto'
alias mkdir='mkdir -p'

# git
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all -30'
alias gp='git push'
alias gpl='git pull --ff-only'

# infra
alias k='kubectl'
alias tf='terraform'

# ==============================================================================
# Functions
# ==============================================================================

mkcd() {
  mkdir -p "$1" && cd "$1"
}

reload-zsh() {
  source "$HOME/.zshrc"
}

path-list() {
  print -l $path
}

which-all() {
  whence -a "$@"
}

zsh-startup-time() {
  for i in {1..5}; do
    /usr/bin/time zsh -i -c exit
  done
}

zsh-plugins-update() {
  local dir

  for dir in "$ZSH_PLUGIN_DIR"/*(/N); do
    if [[ -d "$dir/.git" ]]; then
      print -P "%F{244}Updating ${dir:t}...%f"
      command git -C "$dir" pull --ff-only
    fi
  done
}

# ==============================================================================
# Directory jump — zoxide
# ==============================================================================

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ==============================================================================
# Prompt — Starship
# ==============================================================================
#
# 設定ファイル: starship/starship.toml -> ~/.config/starship.toml
# install.sh でシンボリックリンクを張る

export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

eval "$(starship init zsh)"
