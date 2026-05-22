#!/bin/bash

# Homebrewのパスを設定
setup_brew_path() {
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Homebrewのインストール
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  setup_brew_path
fi

# brewのパスを通す（現在のセッション）
setup_brew_path

# .zprofileにbrewのパスを追加（まだなければ）
if ! grep -q "brew shellenv" ~/.zprofile 2>/dev/null; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  elif [[ -f /usr/local/bin/brew ]]; then
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
  fi
fi

# brew bundle
brew bundle --file ~/dotfiles/packages/Brewfile

# Docker (Colima経由)
if ! command -v docker &>/dev/null; then
  brew install docker docker-compose colima
fi

source "$SCRIPT_DIR/scripts/ai-tools.sh"
select_and_install_ai_tools

# Colimaの起動（まだ起動していない場合）
if command -v colima &>/dev/null; then
  if ! colima status &>/dev/null; then
    colima start
  fi
fi
