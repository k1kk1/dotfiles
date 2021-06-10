# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
# bat settings
# alias
# bat settings
if [[ $(command -v bat) ]]; then
        alias cat='bat'
elif [[ $(command -v batcat) ]]; then
  alias cat="batcat"
fi
# exa settings
if [[ $(command -v exa) ]]; then
        alias exa="exa --icons"
        alias ls="exa"
        alias ll="exa -al --git"
        alias lla="exa -aal"
        alias lt='exa -T -L 3 -a -I "node_modules|.git|.cache" --icons'
        alias lt='exa -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
fi
# ripgrep
if [[ $(command -v rg) ]]; then
        alias grep='rg'
fi
# vim
if [[ $(command -v nvim) ]]; then
        alias vim='nvim'
        alias vi='nvim'
elif [[ $(command -v vim) ]]; then
        alias vim='vim'
        alias vi='vim'
fi

# anyenv settings
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
