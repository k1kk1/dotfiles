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
