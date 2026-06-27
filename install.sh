#!/usr/bin/env zsh
# dotfiles セットアップスクリプト
# 何度実行しても安全（冪等）

set -euo pipefail

DOTFILES_DIR="${0:A:h}"
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# ------------------------------------------------------------------------------
# ユーティリティ
# ------------------------------------------------------------------------------

_ok()   { print -P "%F{002}✔%f $1" }
_skip() { print -P "%F{244}–%f $1" }
_fail() { print -P "%F{001}✘%f $1" }
_head() { print -P "\n%F{004}==>%f %B$1%b" }

# ------------------------------------------------------------------------------
# 1. Homebrew ツール
# ------------------------------------------------------------------------------

_head "Homebrew ツール"

_brew_install() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    _skip "$pkg (already installed)"
  else
    print "  installing $pkg..."
    brew install "$pkg" && _ok "$pkg" || _fail "$pkg"
  fi
}

for pkg in fzf fd bat eza ripgrep jq yq direnv zoxide starship tmux; do
  _brew_install "$pkg"
done

# ------------------------------------------------------------------------------
# 2. Zsh プラグイン
# ------------------------------------------------------------------------------

_head "Zsh プラグイン"

mkdir -p "$ZSH_PLUGIN_DIR"

_plugin_install() {
  local repo="$1"
  local name="${repo##*/}"
  local dest="$ZSH_PLUGIN_DIR/$name"

  if [[ -d "$dest/.git" ]]; then
    _skip "$name (already cloned)"
  else
    print "  cloning $repo..."
    git clone --depth=1 "https://github.com/$repo" "$dest" && _ok "$name" || _fail "$name"
  fi
}

_plugin_install "zsh-users/zsh-autosuggestions"
_plugin_install "zsh-users/zsh-syntax-highlighting"
_plugin_install "zsh-users/zsh-completions"

# ------------------------------------------------------------------------------
# 3. シンボリックリンク
# ------------------------------------------------------------------------------

_head "シンボリックリンク"

_symlink() {
  local src="$1"
  local dst="$2"
  local label="${dst/$HOME/~}"

  if [[ "$(readlink "$dst" 2>/dev/null)" == "$src" ]]; then
    _skip "$label (already linked)"
    return
  fi

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    _ok "既存 ${label} を ${backup/$HOME/~} にバックアップ"
  fi

  mkdir -p "${dst:h}"
  ln -sfn "$src" "$dst"
  _ok "$label -> ${src/$HOME/~}"
}

_symlink "$DOTFILES_DIR/zsh/.zshrc"          "$HOME/.zshrc"
_symlink "$DOTFILES_DIR/git/.gitconfig"      "$HOME/.gitconfig"
_symlink "$DOTFILES_DIR/starship/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
_symlink "$DOTFILES_DIR/ghostty/config"      "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
_symlink "$DOTFILES_DIR/tmux/.tmux.conf"     "$HOME/.tmux.conf"
_symlink "$DOTFILES_DIR/vim"                 "$HOME/.vim"
_symlink "$DOTFILES_DIR/vim"                 "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
_symlink "$DOTFILES_DIR/vim/init.vim"        "$HOME/.vimrc"

# ------------------------------------------------------------------------------
# 4. 動作確認
# ------------------------------------------------------------------------------

_head "動作確認"

# 構文チェック
if zsh -n "$DOTFILES_DIR/zsh/.zshrc" 2>&1; then
  _ok ".zshrc 構文エラーなし"
else
  _fail ".zshrc に構文エラーがあります"
fi

# fzf key-bindings
FZF_KB="/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
if [[ -r "$FZF_KB" ]]; then
  _ok "fzf key-bindings: $FZF_KB"
else
  _fail "fzf key-bindings が見つかりません: $FZF_KB"
fi

# starship config
STARSHIP_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
if [[ -r "$STARSHIP_CFG" ]]; then
  _ok "starship config: $STARSHIP_CFG"
else
  _fail "starship.toml が見つかりません: $STARSHIP_CFG"
fi

# tmux config
if tmux -f "$DOTFILES_DIR/tmux/.tmux.conf" -L dotfiles-config-check start-server \; show-options -g mouse \
  2>/dev/null | grep -q '^mouse on$'; then
  _ok ".tmux.conf 構文エラーなし、mouse on"
else
  _fail ".tmux.conf の読み込みに失敗しました"
fi

print -P "\n%F{002}セットアップ完了。%f 新しいターミナルを開くか、以下を実行してください:"
print "  source ~/.zshrc"
