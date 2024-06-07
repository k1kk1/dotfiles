# bat settings
if [[ $(command -v bat) ]]; then
    alias cat='bat'
elif [[ $(command -v batcat) ]]; then
    alias cat="batcat"
fi

# eza settings
if [[ $(command -v eza) ]]; then
    alias eza="eza --icons"
    alias ls="eza"
    alias ll="eza -al --git"
    alias lla="eza -aal"
    alias lt='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
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
