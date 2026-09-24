#!/usr/bin/env bash
# raspi（Ubuntu / arm64）用 dotfiles セットアップスクリプト
#
# main の install.sh は macOS 前提（Homebrew・launchd）なので、同じことを
# Ubuntu 向けに行う。何度実行しても安全（冪等）。
#
#   git clone -b raspi git@github.com:k1kk1/dotfiles.git ~/src/dotfiles
#   bash ~/src/dotfiles/raspi/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RASPI_DIR="$DOTFILES_DIR/raspi"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
LOCAL_BIN="$HOME/.local/bin"

_ok()   { printf '\e[32m✔\e[0m %s\n' "$1"; }
_skip() { printf '\e[90m–\e[0m %s\n' "$1"; }
_fail() { printf '\e[31m✘\e[0m %s\n' "$1"; }
_head() { printf '\n\e[34m==>\e[0m \e[1m%s\e[0m\n' "$1"; }

# ------------------------------------------------------------------------------
# 1. apt パッケージ
# ------------------------------------------------------------------------------
#
# yq は apt 版が Python 製の別物（文法が違う）なので、ここでは入れず下で
# mikefarah/yq（Homebrew と同じ Go 版）のバイナリを入れる。

_head "apt パッケージ"

APT_PKGS=(zsh fzf fd-find bat eza ripgrep jq direnv zoxide starship tmux lazygit vim neovim btop
          build-essential pkg-config curl git)
missing=()
for pkg in "${APT_PKGS[@]}"; do
  dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
done
if ((${#missing[@]})); then
  sudo apt-get update -q
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "${missing[@]}"
  _ok "installed: ${missing[*]}"
else
  _skip "すべて導入済み"
fi

# ------------------------------------------------------------------------------
# 2. Ubuntu で名前が違うツールと yq
# ------------------------------------------------------------------------------

_head "ツールの名前合わせ"

mkdir -p "$LOCAL_BIN"
_link_bin() {
  local src="$1" name="$2"
  if [[ "$(readlink "$LOCAL_BIN/$name" 2>/dev/null)" == "$src" ]]; then
    _skip "$name (already linked)"
  else
    ln -sfn "$src" "$LOCAL_BIN/$name" && _ok "$name -> $src"
  fi
}
_link_bin /usr/bin/fdfind fd
_link_bin /usr/bin/batcat bat

if "$LOCAL_BIN/yq" --version 2>/dev/null | grep -q mikefarah; then
  _skip "yq (already installed)"
else
  curl -fsSL -o "$LOCAL_BIN/yq" https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64
  chmod +x "$LOCAL_BIN/yq"
  _ok "yq $("$LOCAL_BIN/yq" --version | awk '{print $NF}')"
fi

# ------------------------------------------------------------------------------
# 3. Zsh プラグイン
# ------------------------------------------------------------------------------

_head "Zsh プラグイン"

mkdir -p "$ZSH_PLUGIN_DIR"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting \
            zsh-users/zsh-completions wbingli/zsh-claudecode-completion; do
  name="${repo##*/}"
  if [[ -d "$ZSH_PLUGIN_DIR/$name/.git" ]]; then
    _skip "$name (already cloned)"
  else
    git clone -q --depth=1 "https://github.com/$repo" "$ZSH_PLUGIN_DIR/$name" && _ok "$name"
  fi
done

# ------------------------------------------------------------------------------
# 4. シンボリックリンク
# ------------------------------------------------------------------------------
#
# 既存のファイル（リンクでないもの）は .backup.<日時> に退避してから張る。

_head "シンボリックリンク"

_symlink() {
  local src="$1" dst="$2" label="${2/#$HOME/\~}"
  if [[ "$(readlink "$dst" 2>/dev/null)" == "$src" ]]; then
    _skip "$label (already linked)"
    return
  fi
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    _ok "既存 $label を ${backup/#$HOME/\~} にバックアップ"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  _ok "$label -> ${src/#$HOME/\~}"
}

# main と共通（ghostty は GUI なので除く）
_symlink "$DOTFILES_DIR/zsh/.zshrc"              "$HOME/.zshrc"
_symlink "$DOTFILES_DIR/git/.gitconfig"          "$HOME/.gitconfig"
_symlink "$DOTFILES_DIR/starship/starship.toml"  "$CONFIG_DIR/starship.toml"
_symlink "$DOTFILES_DIR/herdr/config.toml"       "$CONFIG_DIR/herdr/config.toml"
_symlink "$DOTFILES_DIR/tmux/.tmux.conf"         "$HOME/.tmux.conf"
_symlink "$DOTFILES_DIR/vim"                     "$HOME/.vim"
_symlink "$DOTFILES_DIR/vim"                     "$CONFIG_DIR/nvim"
_symlink "$DOTFILES_DIR/vim/init.vim"            "$HOME/.vimrc"

# raspi 専用
_symlink "$RASPI_DIR/zsh/zshenv"                 "$HOME/.zshenv"
_symlink "$RASPI_DIR/zsh/zlogout"                "$HOME/.zlogout"
_symlink "$RASPI_DIR/zsh/fzf.zsh"                "$HOME/.fzf.zsh"
_symlink "$RASPI_DIR/lazygit/config.yml"         "$CONFIG_DIR/lazygit/config.yml"
_symlink "$RASPI_DIR/bin/prompt-sysinfo"         "$LOCAL_BIN/prompt-sysinfo"
_symlink "$RASPI_DIR/btop/raspi.theme"           "$CONFIG_DIR/btop/themes/raspi.theme"

# btop.conf は btop が終了時に書き換えるのでリンクせず、無いときだけ初期値を置く
if [[ -e "$CONFIG_DIR/btop/btop.conf" ]]; then
  _skip "~/.config/btop/btop.conf (already exists)"
else
  printf '%s\n' 'color_theme = "raspi"' 'theme_background = True' 'truecolor = True' \
    'update_ms = 2000' 'proc_sorting = "cpu lazy"' > "$CONFIG_DIR/btop/btop.conf"
  _ok "~/.config/btop/btop.conf（テーマ raspi）"
fi

# ------------------------------------------------------------------------------
# 5. ログインシェル
# ------------------------------------------------------------------------------

_head "ログインシェル"

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$(command -v zsh)" ]]; then
  _skip "zsh (already default)"
else
  sudo chsh -s "$(command -v zsh)" "$USER" && _ok "ログインシェルを zsh に変更"
fi

# ------------------------------------------------------------------------------
# 6. herdr とプラグイン
# ------------------------------------------------------------------------------
#
# herdr 0.9 の `herdr plugin link` は登録だけでビルドしないので、
# マニフェストの [[build]] と同じ cargo build --release を別に実行する。

_head "herdr とプラグイン"

export PATH="$HOME/.cargo/bin:$LOCAL_BIN:$PATH"

if command -v herdr &>/dev/null; then
  _skip "herdr $(herdr --version | awk '{print $2}') (already installed)"
else
  curl -fsSL https://herdr.dev/install.sh | sh && _ok "herdr"
fi

if command -v cargo &>/dev/null; then
  _skip "rust (already installed)"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
  _ok "rust"
fi

HERDR_PLUGINS_REPO="${HERDR_PLUGINS_REPO:-git@github.com:k1kk1/herdr-plugins.git}"
HERDR_PLUGINS_DIR="$HOME/src/herdr-plugins"
HERDR_PLUGINS=(herdr-pane-manager herdr-layout-tools herdr-navigator herdr-command-palette herdr-sessions herdr-open)

if [[ -d "$HERDR_PLUGINS_DIR/.git" ]]; then
  _skip "${HERDR_PLUGINS_DIR/#$HOME/\~} (already cloned)"
elif git clone -q --depth=1 "$HERDR_PLUGINS_REPO" "$HERDR_PLUGINS_DIR"; then
  _ok "${HERDR_PLUGINS_DIR/#$HOME/\~}"
else
  _fail "herdr-plugins の clone に失敗（private リポジトリ。GitHub の SSH 鍵を確認）"
fi

# plugin link はサーバー経由なので、動いていなければ裏で起動する
herdr plugin list &>/dev/null || { setsid herdr server >/dev/null 2>&1 < /dev/null & sleep 3; }

if [[ -d "$HERDR_PLUGINS_DIR" ]]; then
  for plugin in "${HERDR_PLUGINS[@]}"; do
    root="$HERDR_PLUGINS_DIR/$plugin"
    if ! (cd "$root" && cargo build --release -q); then
      _fail "$plugin (build に失敗)"
      continue
    fi
    herdr plugin link "$root" &>/dev/null && _ok "$plugin" || _fail "$plugin (link に失敗)"
  done
fi

# ------------------------------------------------------------------------------
# 7. 動作確認
# ------------------------------------------------------------------------------

_head "動作確認"

zsh -n "$DOTFILES_DIR/zsh/.zshrc" && _ok ".zshrc 構文エラーなし" || _fail ".zshrc に構文エラー"
zsh -n "$RASPI_DIR/zsh/palette.zsh" && _ok "palette.zsh 構文エラーなし" || _fail "palette.zsh に構文エラー"
herdr config check &>/dev/null && _ok "herdr config 構文エラーなし" || _fail "herdr config の読み込みに失敗"
herdr server reload-config &>/dev/null && _ok "herdr 設定を再読み込み" || _skip "herdr サーバー未起動（次回起動時に反映）"
starship prompt &>/dev/null && _ok "starship 表示 OK" || _fail "starship の表示に失敗"

printf '\n\e[32mセットアップ完了。\e[0m 新しいターミナルを開くか、exec zsh を実行してください。\n'
