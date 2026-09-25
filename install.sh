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

for pkg in fzf fd bat eza ripgrep jq yq direnv zoxide starship tmux herdr lazygit; do
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
_plugin_install "wbingli/zsh-claudecode-completion"

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
_symlink "$DOTFILES_DIR/herdr/config.toml"     "${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"
_symlink "$DOTFILES_DIR/tmux/.tmux.conf"     "$HOME/.tmux.conf"
_symlink "$DOTFILES_DIR/vim"                 "$HOME/.vim"
_symlink "$DOTFILES_DIR/vim"                 "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
_symlink "$DOTFILES_DIR/vim/init.vim"        "$HOME/.vimrc"

# ------------------------------------------------------------------------------
# 4. Herdr プラグイン
# ------------------------------------------------------------------------------
#
# 自作プラグイン6種を clone → build → link する。
# herdr plugin link はマニフェストの [[build]]（cargo build --release）を
# 実行するので、ここでは link を呼ぶだけでビルドまで済む。差分が無ければ
# cargo が即座に返すため、毎回実行しても待たされない。

_head "Herdr プラグイン"

HERDR_PLUGINS_REPO="${HERDR_PLUGINS_REPO:-git@github.com:k1kk1/herdr-plugins.git}"
HERDR_PLUGINS_DIR="${HERDR_PLUGINS_DIR:-$HOME/src/herdr-plugins}"
HERDR_PLUGINS=(herdr-pane-manager herdr-layout-tools herdr-navigator herdr-command-palette herdr-sessions herdr-open)

_herdr_plugins_setup() {
  # cargo は rustup 経由で入れている想定。PATH に無いことがあるので補う。
  [[ -d "$HOME/.cargo/bin" ]] && PATH="$HOME/.cargo/bin:$PATH"

  if ! command -v cargo &>/dev/null; then
    _fail "cargo が見つかりません。プラグインをスキップします"
    print "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    return
  fi

  # plugin link はソケット API 経由なので、サーバが動いていないと失敗する。
  if ! herdr plugin list &>/dev/null; then
    _skip "Herdr サーバに接続できません。herdr を起動してから再実行してください"
    return
  fi

  if [[ -d "$HERDR_PLUGINS_DIR/.git" ]]; then
    _skip "${HERDR_PLUGINS_DIR/$HOME/~} (already cloned)"
  else
    print "  cloning $HERDR_PLUGINS_REPO..."
    if git clone --depth=1 "$HERDR_PLUGINS_REPO" "$HERDR_PLUGINS_DIR" 2>/dev/null; then
      _ok "${HERDR_PLUGINS_DIR/$HOME/~}"
    else
      _fail "clone に失敗しました（private リポジトリです。gh auth login か SSH 鍵を確認してください）"
      return
    fi
  fi

  # config.toml のキーバインドは既定の場所を指しているので、ずれたら知らせる。
  if [[ "$HERDR_PLUGINS_DIR" != "$HOME/src/herdr-plugins" ]]; then
    _fail "herdr/config.toml は ~/src/herdr-plugins を前提にしています。パスを合わせてください"
  fi

  # 初回は link の中で cargo build が走り、数分は無言になる。出力を捨てている
  # ので、先に断っておかないと固まったように見える。
  if [[ ! -x "$HERDR_PLUGINS_DIR/herdr-pane-manager/target/release/herdr-pane-manager" ]]; then
    print "  初回ビルドに数分かかります..."
  fi

  local plugin
  for plugin in $HERDR_PLUGINS; do
    local root="$HERDR_PLUGINS_DIR/$plugin"
    if [[ ! -f "$root/herdr-plugin.toml" ]]; then
      _fail "$plugin (マニフェストが見つかりません)"
      continue
    fi
    if herdr plugin link "$root" &>/dev/null; then
      _ok "$plugin"
    else
      _fail "$plugin (link に失敗)"
    fi
  done
}

_herdr_plugins_setup

# ------------------------------------------------------------------------------
# 5. Herdr サイドバーの metadata
# ------------------------------------------------------------------------------
#
# サイドバーの $num / $dir（Workspace）と、Codex の Pane の $task / $summary /
# $model を更新し続ける常駐プロセス（herdr/bin/herdr-sidebar-meta）を
# LaunchAgent として登録する。Herdr の組み込みトークンには無い値なので、
# metadata として外から流し込んでいる。

_head "Herdr サイドバーの metadata"

_herdr_sidebar_meta_setup() {
  local label="dev.herdr.sidebar-meta"
  local src="$DOTFILES_DIR/herdr/launchd/$label.plist"
  local dst="$HOME/Library/LaunchAgents/$label.plist"

  # plist の中で $HOME/src/dotfiles を直接指している（launchd が変数を
  # 展開しないので /bin/sh 経由）。置き場所がずれたら気付けるようにする。
  if [[ "$DOTFILES_DIR" != "$HOME/src/dotfiles" ]]; then
    _fail "$label.plist は ~/src/dotfiles を前提にしています。パスを合わせてください"
    return
  fi

  _symlink "$src" "$dst"

  launchctl bootout "gui/$UID/$label" &>/dev/null || true
  if launchctl bootstrap "gui/$UID" "$dst" &>/dev/null; then
    _ok "$label を起動しました"
  else
    _fail "$label の起動に失敗しました (launchctl bootstrap)"
  fi
}

_herdr_sidebar_meta_setup

# ------------------------------------------------------------------------------
# 6. Claude Code hooks（Agent 行の $model / $summary）
# ------------------------------------------------------------------------------
#
# ~/.claude/settings.json は dotfiles の管理外（マシン固有の設定が入る）なので、
# シンボリックリンクではなく hooks の部分だけを jq でマージする。
# 同じコマンドが既に登録されていれば何もしない。

_head "Claude Code hooks"

_claude_hooks_setup() {
  local snippet="$DOTFILES_DIR/herdr/claude-hooks.json"
  local settings="$HOME/.claude/settings.json"
  local cmd='"$HOME/src/dotfiles/herdr/bin/herdr-agent-meta"'

  if ! command -v jq &>/dev/null; then
    _fail "jq が見つかりません。hooks の追加をスキップします"
    return
  fi

  if [[ ! -f "$settings" ]]; then
    _fail "${settings/$HOME/~} がありません。Claude Code を一度起動してください"
    return
  fi

  if jq -e --arg cmd "$cmd" \
      '[.hooks // {} | .[]? | .[]? | .hooks[]? | .command] | index($cmd)' \
      "$settings" &>/dev/null; then
    _skip "herdr-agent-meta hooks (already registered)"
    return
  fi

  # 壊すと Claude Code の設定が丸ごと無効になるので、退避してから書き換える。
  local backup="$settings.backup.$(date +%Y%m%d%H%M%S)"
  cp "$settings" "$backup"

  # `*` での合成だと既存の同じイベントの配列ごと置き換わってしまうので、
  # イベントごとに配列へ足す形でマージする。
  local tmp="$settings.tmp.$$"
  if jq --slurpfile add "$snippet" '
        .hooks = (
          reduce ($add[0].hooks | to_entries[]) as $e
            (.hooks // {}; .[$e.key] = ((.[$e.key] // []) + $e.value))
        )' "$settings" > "$tmp" && jq -e . "$tmp" &>/dev/null; then
    mv "$tmp" "$settings"
    _ok "herdr-agent-meta hooks を追加 (backup: ${backup/$HOME/~})"
  else
    rm -f "$tmp"
    _fail "hooks のマージに失敗しました"
  fi
}

_claude_hooks_setup

# ------------------------------------------------------------------------------
# 7. 動作確認
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

# Herdr config
if HERDR_CONFIG_PATH="$DOTFILES_DIR/herdr/config.toml" herdr config check &>/dev/null; then
  _ok "Herdr config 構文エラーなし"
else
  _fail "Herdr config の読み込みに失敗しました"
fi

# Herdr プラグイン
if herdr plugin list &>/dev/null; then
  _linked=$(herdr plugin list 2>/dev/null | grep -c "enabled" || true)
  if [[ "$_linked" -ge 5 ]]; then
    _ok "Herdr プラグイン $_linked 個が有効"
  else
    _fail "Herdr プラグインが $_linked 個しか有効になっていません（5個必要）"
  fi
else
  _skip "Herdr サーバ未起動のためプラグイン確認をスキップ"
fi

print -P "\n%F{002}セットアップ完了。%f 新しいターミナルを開くか、以下を実行してください:"
print "  source ~/.zshrc"
