#!/bin/bash

chsh -s $(which zsh)

sudo apt-get update && sudo apt-get upgrade -y

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

ln -s $PWD/.zshrc $HOME/.zshrc

ln -s $PWD/.p10k.zsh $HOME/.p10k.zsh
