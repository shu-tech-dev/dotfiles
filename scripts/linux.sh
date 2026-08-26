#!/bin/bash

# Homebrewのパスを設定
setup_brew_path() {
  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

# ビルドツールとzshのインストール（未導入のものだけを記録する）
apt_install_tracked build-essential curl git zsh unzip

# Homebrewのインストール
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  manifest_record homebrew /home/linuxbrew/.linuxbrew
  setup_brew_path
fi

# brewのパスを通す（現在のセッション）
setup_brew_path

# .bashrcにbrewのパスを追加（まだなければ）
append_rc_line "$HOME/.bashrc" \
  'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' \
  'linuxbrew'

# brew bundle（新規に入ったformulaだけがマニフェストに記録される）
run_brew_bundle "$SCRIPT_DIR/packages/Brewfile"

# このプラットフォームで必須のツール（WSLならwin32yankなど）
pkg_install_required "$SCRIPT_DIR/packages/tools.json"

source "$SCRIPT_DIR/scripts/ai-tools.sh"
select_and_install_ai_tools
