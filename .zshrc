### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-bin-gem-node \
    zdharma-continuum/z-a-rust

# zinit settings
## 補完
zinit light zsh-users/zsh-autosuggestions
## シンタックスハイライト
zinit light zdharma-continuum/fast-syntax-highlighting
## コマンド履歴を検索 Ctrl+r
zinit light zdharma-continuum/history-search-multi-word

# junegunn/fzf-bin
zinit ice from"gh-r" as"program"
zinit light junegunn/fzf-bin

# sharkdp/fd
zinit ice as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

# sharkdp/bat
zinit ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

# ogham/exa, replacement for ls
zinit ice wait"2" lucid from"gh-r" as"program" mv"exa* -> exa"
zinit light ogham/exa

# powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

#---------------------------------------------------------------------------------------------------------
### Prompt settings
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#---------------------------------------------------------------------------------------------------------
### Path settings
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH

#---------------------------------------------------------------------------------------------------------
### alias settings
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

#---------------------------------------------------------------------------------------------------------
### Other settings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
