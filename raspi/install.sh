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

APT_PKGS=(zsh fzf fd-find bat eza ripgrep jq direnv zoxide starship tmux lazygit vim neovim btop nvme-cli sqlite3
          python3-matplotlib python3-requests
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
# 7. ログイン時の表示
# ------------------------------------------------------------------------------
#
# Ubuntu 標準の案内（リンク・宣伝・IP アドレスなど約 35 行）を止め、
# raspi/motd/05-raspi（鍵の期限・稼働時間・問題があるときの警告）に置き換える。
# 標準のスクリプトは dpkg-statoverride で実行権を外すので、パッケージ更新後も止まったまま。
# 問題があるときだけ表示するもの（電源の警告・overlayroot・fsck）は残す。

_head "ログイン時の表示"

sudo install -m 755 "$RASPI_DIR/motd/05-raspi" /etc/update-motd.d/05-raspi
_ok "/etc/update-motd.d/05-raspi"

MOTD_DISABLE=(
  /etc/update-motd.d/00-header /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news
  /etc/update-motd.d/85-fwupd /etc/update-motd.d/90-piboot-try /etc/update-motd.d/90-updates-available
  /etc/update-motd.d/91-contract-ua-esm-status /etc/update-motd.d/91-release-upgrade
  /etc/update-motd.d/92-unattended-upgrades /etc/update-motd.d/95-hwe-eol
  /etc/update-motd.d/98-reboot-required /usr/share/landscape/landscape-sysinfo.wrapper
)
for f in "${MOTD_DISABLE[@]}"; do
  [[ -e $f ]] || continue
  if sudo dpkg-statoverride --list "$f" &>/dev/null; then
    _skip "${f##*/} (already disabled)"
  else
    sudo dpkg-statoverride --update --add root root 0644 "$f" && _ok "${f##*/} を停止"
  fi
done

if [[ -f /etc/ssh/sshd_config.d/raspi.conf ]]; then
  _skip "sshd: Last login の表示 (already disabled)"
else
  echo "PrintLastLog no" | sudo tee /etc/ssh/sshd_config.d/raspi.conf >/dev/null
  sudo systemctl reload ssh && _ok "sshd: Last login の表示を停止"
fi

# ------------------------------------------------------------------------------
# 8. microSD の予備環境の更新（週 1 回）
# ------------------------------------------------------------------------------
#
# NVMe の中身を microSD に複製して、NVMe が起動できないときの予備環境を直近の状態に保つ。

_head "microSD の予備環境の更新"

sudo install -m 755 "$RASPI_DIR/backup/raspi-sd-sync" /usr/local/sbin/raspi-sd-sync
sudo install -m 644 "$RASPI_DIR/backup/raspi-sd-sync.service" /etc/systemd/system/raspi-sd-sync.service
sudo install -m 644 "$RASPI_DIR/backup/raspi-sd-sync.timer" /etc/systemd/system/raspi-sd-sync.timer
sudo systemctl daemon-reload
sudo systemctl enable --now -q raspi-sd-sync.timer
_ok "raspi-sd-sync.timer（次回: $(systemctl show raspi-sd-sync.timer -p NextElapseUSecRealtime --value)）"

# ------------------------------------------------------------------------------
# 9. 通知（Discord）と Claude Code / Codex の設定
# ------------------------------------------------------------------------------
#
# 通知は Discord の Webhook に送る。URL は秘密情報なのでリポジトリに入れず、
# ~/.config/raspi-notify/discord-webhook に 1 行で書く（無いあいだは journal に記録するだけ）。

_head "通知と Agent の設定"

sudo install -m 755 "$RASPI_DIR/bin/raspi-notify" /usr/local/bin/raspi-notify
sudo install -m 755 "$RASPI_DIR/bin/raspi-hc" /usr/local/bin/raspi-hc
sudo install -m 755 "$RASPI_DIR/alert/raspi-alert" /usr/local/sbin/raspi-alert
sudo install -m 644 "$RASPI_DIR/alert/raspi-alert.service" /etc/systemd/system/raspi-alert.service
sudo install -m 644 "$RASPI_DIR/alert/raspi-alert.timer" /etc/systemd/system/raspi-alert.timer
sudo systemctl daemon-reload
sudo systemctl enable --now -q raspi-alert.timer
_ok "raspi-notify / raspi-alert.timer（5 分ごと）"

sudo install -m 755 "$RASPI_DIR/report/raspi-daily-report" /usr/local/bin/raspi-daily-report
sudo install -m 644 "$RASPI_DIR/report/raspi-daily-report.service" /etc/systemd/system/raspi-daily-report.service
sudo install -m 644 "$RASPI_DIR/report/raspi-daily-report.timer" /etc/systemd/system/raspi-daily-report.timer
sudo systemctl daemon-reload
sudo systemctl enable --now -q raspi-daily-report.timer
_ok "raspi-daily-report.timer（毎朝 8 時に過去 24 時間のグラフ）"

sudo install -m 755 "$RASPI_DIR/schedule/raspi-schedule-collect" /usr/local/sbin/raspi-schedule-collect
sudo install -m 644 "$RASPI_DIR/schedule/raspi-schedule-collect".{service,timer,path} /etc/systemd/system/
sudo install -d -m 755 /var/lib/raspi-schedule
sudo install -m 644 "$RASPI_DIR/schedule/"{index.html,services.html,app.css,common.js} /var/lib/raspi-schedule/
sudo systemctl daemon-reload
sudo systemctl enable --now -q raspi-schedule-collect.timer raspi-schedule-collect.path
sudo systemctl start raspi-schedule-collect.service
if tailscale serve status 2>/dev/null | grep -q "/schedule/"; then
  _skip "定期実行・常駐ページの公開 (already configured)"
else
  sudo tailscale serve --bg --https=443 --set-path=/schedule/ /var/lib/raspi-schedule >/dev/null
fi
_ok "定期実行・常駐ページ（https://$(tailscale status --json | jq -r .Self.DNSName | sed "s/\\.$//")/schedule/）"

mkdir -p "$CONFIG_DIR/raspi-notify" && chmod 700 "$CONFIG_DIR/raspi-notify"
if [[ -s "$CONFIG_DIR/raspi-notify/discord-webhook" ]]; then
  chmod 600 "$CONFIG_DIR/raspi-notify/discord-webhook"
  _skip "Discord の Webhook (already configured)"
else
  _skip "Discord の Webhook が未設定（~/.config/raspi-notify/discord-webhook に URL を書くと送信される）"
fi
if [[ -s "$CONFIG_DIR/raspi-notify/healthchecks-ping-key" ]]; then
  chmod 600 "$CONFIG_DIR/raspi-notify/healthchecks-ping-key"
  _skip "Healthchecks.io の ping key (already configured)"
else
  _skip "Healthchecks.io の ping key が未設定（~/.config/raspi-notify/healthchecks-ping-key に書くと死活監視が始まる）"
fi

# Claude Code: 指示書はリンク。settings.json は Claude Code も書き換えるので、必要な部分だけ足し込む
_symlink "$RASPI_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
settings="$HOME/.claude/settings.json"
[[ -f $settings ]] || echo '{}' > "$settings"
merged="$settings.tmp.$$"
jq -s -f "$RASPI_DIR/claude/merge-settings.jq" "$settings" "$RASPI_DIR/claude/settings.json" > "$merged"
if cmp -s "$settings" "$merged"; then
  rm -f "$merged"
  _skip "~/.claude/settings.json (already merged)"
else
  cp "$settings" "$settings.backup.$(date +%Y%m%d%H%M%S)"
  mv "$merged" "$settings"
  _ok "~/.claude/settings.json に権限と通知の hooks を追加"
fi

# Codex: notify はトップレベルの項目なので、ファイルの先頭に入れる
codex_cfg="$HOME/.codex/config.toml"
mkdir -p "$HOME/.codex"; touch "$codex_cfg"
if grep -q '^notify' "$codex_cfg"; then
  _skip "~/.codex/config.toml の notify (already set)"
else
  { printf 'notify = ["%s"]\n\n' "$RASPI_DIR/bin/codex-notify"; cat "$codex_cfg"; } > "$codex_cfg.tmp.$$"
  mv "$codex_cfg.tmp.$$" "$codex_cfg"
  _ok "~/.codex/config.toml に完了通知を追加"
fi

# ------------------------------------------------------------------------------
# 10. 動作確認
# ------------------------------------------------------------------------------

_head "動作確認"

zsh -n "$DOTFILES_DIR/zsh/.zshrc" && _ok ".zshrc 構文エラーなし" || _fail ".zshrc に構文エラー"
zsh -n "$RASPI_DIR/zsh/palette.zsh" && _ok "palette.zsh 構文エラーなし" || _fail "palette.zsh に構文エラー"
herdr config check &>/dev/null && _ok "herdr config 構文エラーなし" || _fail "herdr config の読み込みに失敗"
herdr server reload-config &>/dev/null && _ok "herdr 設定を再読み込み" || _skip "herdr サーバー未起動（次回起動時に反映）"
starship prompt &>/dev/null && _ok "starship 表示 OK" || _fail "starship の表示に失敗"

printf '\n\e[32mセットアップ完了。\e[0m 新しいターミナルを開くか、exec zsh を実行してください。\n'
