# raspi カラーテーマ: 黄緑のサイバーパンク（Even Realities 風）
#
# raspi/zsh/zshenv（~/.zshenv）から「対話シェルかつ端末に繋がっているとき」だけ読み込まれる。
# ログイン中だけ手元のターミナル（Ghostty / VS Code）の配色を書き換え、
# raspi/zsh/zlogout（~/.zlogout）で元に戻す。Mac と見分けるのが目的。
#
#   背景 #070A06 / 文字 #C8F7A0 / アクセント #B6FF3B（黄緑）
#   警告 #FFD23B / エラー #FF3B6B

# ANSI 16 色（0-7 通常、8-15 明るい色）。ls・git・eza などはこの色で表示される
typeset -ga RASPI_ANSI=(
  0B1108 FF3B6B 5CFF7A D4FF3B 3BD6A0 B98BFF 3BFFD1 B8D8A0
  3D5230 FF6E8F 9DFF6E E8FF8A 7FEBC4 D4B0FF 8AFFE6 F0FFE0
)

_raspi_theme_apply() {
  local i seq=""
  for i in {1..16}; do
    seq+=$'\e]4;'"$((i - 1));#${RASPI_ANSI[i]}"$'\a'
  done
  # 10: 文字色 / 11: 背景色 / 12: カーソル色
  seq+=$'\e]10;#C8F7A0\a\e]11;#070A06\a\e]12;#B6FF3B\a'
  print -rn -- "$seq" 2>/dev/null > /dev/tty
}

_raspi_theme_reset() {
  print -rn -- $'\e]104\a\e]110\a\e]111\a\e]112\a' 2>/dev/null > /dev/tty
}

# 端末の配色を使うツールの設定
export BAT_THEME="ansi"
export FZF_DEFAULT_OPTS="--color=fg:#C8F7A0,bg:-1,hl:#B6FF3B,fg+:#F0FFE0,bg+:#1A2A10,hl+:#D4FF3B,info:#6B8F3A,prompt:#B6FF3B,pointer:#B6FF3B,marker:#5CFF7A,spinner:#3BFFD1,header:#6B8F3A,border:#3D5230,gutter:-1"

_raspi_theme_apply
