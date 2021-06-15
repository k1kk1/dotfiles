## Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

# zinit settings
zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma/fast-syntax-highlighting

zinit load zdharma/history-search-multi-word

# ripgrep
zinit ice as"program" from"gh-r" mv"ripgrep* -> rg" pick"rg/rg"
zinit light BurntSushi/ripgrep

# exa
zinit ice as"program" from"gh-r" mv"exa* -> exa"
zinit light ogham/exa

# bat
zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

# fd
zinit ice as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

# fzf
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

## alias settings
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# anyenv settings
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

#
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
