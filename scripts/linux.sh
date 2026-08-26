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

# WSLではNeovimがWindowsのクリップボードを読み書きするのにwin32yankが要る。
# 無いとNeovimはclip.exe経由にフォールバックし、UTF-8非対応で日本語が化ける。
if grep -qi microsoft /proc/version && ! command -v win32yank.exe &>/dev/null; then
  curl -fsSL -o /tmp/win32yank.zip \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  # 展開に失敗したときPATH上に0バイトのexeを残さないよう、成功してから配置する
  unzip -p /tmp/win32yank.zip win32yank.exe > /tmp/win32yank.exe
  install -Dm755 /tmp/win32yank.exe "$HOME/.local/bin/win32yank.exe"
  rm -f /tmp/win32yank.zip /tmp/win32yank.exe
  manifest_record file "$HOME/.local/bin/win32yank.exe"
fi

source "$SCRIPT_DIR/scripts/ai-tools.sh"
select_and_install_ai_tools
