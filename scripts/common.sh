#!/bin/bash

# nvmのインストール（最新バージョンを動的取得）
if ! command -v nvm &>/dev/null; then
  NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Node.js LTSのインストール
nvm install --lts
nvm use --lts

# TPM (tmux plugin manager) のインストール
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 必須ツールのシンボリックリンク
mkdir -p ~/.config/fd
ln -sfn ~/dotfiles/.config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/.config/tmux ~/.config/tmux
ln -sf ~/dotfiles/.config/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/.config/fd/ignore ~/.config/fd/ignore
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# オプションアプリのインストールとシンボリックリンク
source "$SCRIPT_DIR/scripts/optional-apps.sh"
select_and_install_optional_apps

# zshをデフォルトシェルに設定 (Linux only - macOS uses builtin zsh)
if [[ "$(uname -s)" == "Linux" ]]; then
  ZSH_PATH=$(which zsh)
  if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
    chsh -s "$ZSH_PATH"
  fi
fi
