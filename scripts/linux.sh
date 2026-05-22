#!/bin/bash

# Homebrewのパスを設定
setup_brew_path() {
  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

# ビルドツールとzshのインストール
sudo apt install -y build-essential curl git zsh

# Homebrewのインストール
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  setup_brew_path
fi

# brewのパスを通す（現在のセッション）
setup_brew_path

# .bashrcにbrewのパスを追加（まだなければ）
if ! grep -q "linuxbrew" ~/.bashrc; then
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
fi

# brew bundle
brew bundle --file ~/dotfiles/packages/Brewfile

# Docker CEのインストール
if ! command -v docker &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
fi

# dockerグループへの追加
if getent group docker &>/dev/null; then
  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
  fi
fi

source "$SCRIPT_DIR/scripts/ai-tools.sh"
select_and_install_ai_tools
