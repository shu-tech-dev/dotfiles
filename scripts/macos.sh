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
  manifest_record homebrew "$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
fi

# brewのパスを通す（現在のセッション）
setup_brew_path

# .zprofileにbrewのパスを追加（まだなければ）
if [[ -f /opt/homebrew/bin/brew ]]; then
  append_rc_line "$HOME/.zprofile" 'eval "$(/opt/homebrew/bin/brew shellenv)"' 'brew shellenv'
elif [[ -f /usr/local/bin/brew ]]; then
  append_rc_line "$HOME/.zprofile" 'eval "$(/usr/local/bin/brew shellenv)"' 'brew shellenv'
fi

# brew bundle（新規に入ったformulaだけがマニフェストに記録される）
run_brew_bundle "$SCRIPT_DIR/packages/Brewfile"

# このプラットフォームで必須のツール
pkg_install_required "$SCRIPT_DIR/packages/tools.json"

source "$SCRIPT_DIR/scripts/ai-tools.sh"
select_and_install_ai_tools
