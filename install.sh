#!/bin/bash

for f in .??*
do
    	[[ "$f" == ".git" ]] && continue
    	[[ "$f" == ".DS_Store" ]] && continue
	[[ "$f" == ".vim" ]] && continue
	[[ "$f" == ".vimrc" ]] && continue
	[[ "$f" == ".gitconfig" ]] && continue
	ln -sf ~/dotfiles/$f ~/$f
	echo "ln -sf ~/dotfiles/$f ~/$f"
done

cp ~/dotfiles/.gitconfig ~/.gitconfig
echo "cp ~/dotfiles/.gitconfig ~/.gitconfig"
ln -sf ~/dotfiles/.vimrc ~/.vimrc
echo "ln -sf ~/dotfiles/.vimrc ~/.vimrc"
ln -sf ~/dotfiles/.vim ~/.config/nvim/
echo "ln -sf ~/dotfiles/.vim ~/.vim"
ln -sf ~/dotfiles/.vimrc ~/.config/nvim/init.vim
echo "ln -sf ~/dotfiles/.vimrc ~/.config/nvim/init.vim"


exec $SHELL -l
