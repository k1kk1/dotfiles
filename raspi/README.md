# raspi ブランチ

Raspberry Pi 5（Ubuntu 26.04 / arm64、ホスト名 `raspi`）用の dotfiles。
`main`（Mac）と同じ設定をベースに、Pi だけの設定を足している。

## main との違い

| ファイル | 内容 |
|---|---|
| `starship/starship.toml` | 配色を黄緑のサイバーパンクに変更。上段右端に CPU・メモリ・SoC 温度とホスト名を表示 |
| `herdr/config.toml` | 末尾に raspi 専用テーマ（`[theme]` / `[theme.custom]`）を追加 |
| `raspi/install.sh` | Ubuntu 用のセットアップ（main の `install.sh` は macOS 用） |
| `raspi/zsh/zshenv` → `~/.zshenv` | PATH（cargo・`~/.local/bin`・npm-global）とカラーテーマの読み込み |
| `raspi/zsh/palette.zsh` | カラーテーマ本体。ログイン中だけ手元のターミナルの配色を書き換える |
| `raspi/zsh/zlogout` → `~/.zlogout` | ログアウト時にターミナルの配色を戻す |
| `raspi/zsh/fzf.zsh` → `~/.fzf.zsh` | apt 版 fzf のキーバインドと補完 |
| `raspi/bin/prompt-sysinfo` → `~/.local/bin/` | starship 用に CPU・メモリ・温度を出す |
| `raspi/lazygit/config.yml` → `~/.config/lazygit/` | lazygit の配色 |
| `raspi/btop/raspi.theme` → `~/.config/btop/themes/` | btop の配色（`btop.conf` は btop が書き換えるので管理しない） |
| `raspi/motd/05-raspi` → `/etc/update-motd.d/` | ログイン時の表示（OS・稼働時間・Tailscale の鍵の期限・実行中の Agent と、問題があるときだけ警告）。Ubuntu 標準の案内は `install.sh` が停止する |
| `raspi/backup/` → `/usr/local/sbin`・systemd | 週 1 回（日曜 4 時）NVMe を microSD の予備環境に複製（`raspi-sd-sync`） |
| `raspi/bin/raspi-notify` → `/usr/local/bin` | Discord への通知。Webhook の URL は `~/.config/raspi-notify/discord-webhook`（リポジトリ外） |
| `raspi/alert/` → `/usr/local/sbin`・systemd | 5 分ごとに異常を確認し、変化があったときだけ通知（`raspi-alert`） |
| `raspi/report/` → `/usr/local/bin`・systemd | 毎朝 8 時に過去 24 時間の CPU・メモリ・温度・ディスクのグラフを送る（`raspi-daily-report`） |
| `raspi/bin/raspi-hc` → `/usr/local/bin` | Healthchecks.io への連絡（死活監視とバックアップの見張り）。ping key は `~/.config/raspi-notify/healthchecks-ping-key`（リポジトリ外） |
| `raspi/claude/CLAUDE.md` → `~/.claude/` | Claude Code への Pi の前提と進め方 |
| `raspi/claude/settings.json` | 許可・確認・禁止するコマンドと通知の hooks。`~/.claude/settings.json` に足し込む（リンクしない） |
| `raspi/bin/claude-notify-hook`・`codex-notify` | Claude Code・Codex の完了と入力待ちの通知 |

## セットアップ

```bash
git clone -b raspi git@github.com:k1kk1/dotfiles.git ~/src/dotfiles
bash ~/src/dotfiles/raspi/install.sh
```

## 運用

- **Pi では常に `raspi` ブランチを使う。** `main` を checkout すると `raspi/` が消え、`~/.zshenv` などのリンクが切れて PATH が壊れる
- **Mac（main）の変更を取り込むとき**は、Pi で:

  ```bash
  cd ~/src/dotfiles
  git fetch origin
  git merge origin/main
  bash raspi/install.sh   # 新しいリンクの追加や herdr 設定の再読み込み
  ```

  `starship/starship.toml` と `herdr/config.toml` は両方のブランチで変えているので、main 側で同じ場所が変わると衝突する。raspi 側の配色と追加分を残す形で解消する
- **Pi だけの変更**は `raspi` ブランチにコミットする。Mac にも欲しい変更は `main` に入れてから raspi にマージする

## カラーテーマ

| 用途 | 色 |
|---|---|
| 背景 | `#070A06` |
| 文字 | `#C8F7A0` |
| アクセント（黄緑） | `#B6FF3B` |
| 緑 | `#5CFF7A` |
| 補助（暗いオリーブ） | `#6B8F3A` |
| 警告 | `#FFD23B` |
| エラー | `#FF3B6B` |
