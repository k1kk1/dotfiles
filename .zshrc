### Zinit settings
[[ ! -f ~/.zsh/.zinit.zsh ]] || source ~/.zsh/.zinit.zsh

#---------------------------------------------------------------------------------------------------------
### Prompt settings
[[ ! -f ~/.zsh/.p10k.zsh ]] || source ~/.zsh/.p10k.zsh

#---------------------------------------------------------------------------------------------------------
### alias settings
[[ ! -f ~/.zsh/.alias.zsh ]] || source ~/.zsh/.alias.zsh

#---------------------------------------------------------------------------------------------------------
### Other settings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 補完
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
setopt list_packed          # 補完候補を詰めて表示

# history
setopt share_history        # コマンド履歴ファイルを共有
setopt hist_ignore_all_dups # 重複するコマンド行は古い方を削除
setopt hist_ignore_dups     # 直前と同じコマンドラインはヒストリに追加しない
setopt hist_reduce_blanks   # 余計な空白は除去して記録
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# コマンドミスを修正
setopt correct

# cd
setopt auto_cd
setopt auto_pushd # cd -[tab] 履歴から移動

# comment
setopt interactive_comments

# beep
setopt no_beep

#---------------------------------------------------------------------------------------------------------
### Path settings
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
