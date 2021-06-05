#!/bin/bash

for f in .??*
do
  [[ $f = ".git" ]] && continue
  [[ $f = ".gitconfig" ]] && continue
  [[ $f = ".DS_Store" ]] && continue
  [[ $f = ".vim" ]] && continue
  ln -sf ~/dotfiles/$f ~/$f
  echo "ln -sf ~/dotfiles/$f ~/$f"
done

cp ~/dotfiles/.gitconfig ~/.gitconfig
echo "cp ~/dotfiles/.gitconfig ~/.gitconfig"

ln -sf ~/dotfiles/.vim ~/.config/nvim
echo "ln -sf ~/dotfiles/.vim ~/.config/nvim"

ln -sf ~/dotfiles/.vim ~/.vim
echo "ln -sf ~/dotfiles/.vim ~/.vim"

ln -sf ~/dotfiles/.vim/init.vim ~/.vimrc
echo "ln -sf ~/dotfiles/.vim/init.vim ~/.vimrc"

exec $SHELL -l
