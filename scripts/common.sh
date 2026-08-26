#!/bin/bash

# nvmが把握しているNodeバージョンの一覧
_nvm_versions() {
  nvm ls --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u
}

# nvmのインストール（最新バージョンを動的取得）
if ! command -v nvm &>/dev/null; then
  NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  manifest_record nvm "$NVM_DIR"
fi

# Node.js LTSのインストール（新規に入ったバージョンだけを記録）
NODE_BEFORE=$(_nvm_versions)
nvm install --lts
nvm use --lts
while IFS= read -r v; do
  [ -n "$v" ] && manifest_record node "$v"
done < <(comm -13 <(echo "$NODE_BEFORE") <(_nvm_versions))

# TPM (tmux plugin manager) のインストール
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  manifest_record tpm "$HOME/.tmux/plugins/tpm"
fi

# 必須ツールのシンボリックリンク
# link_dotfile は既存の実体をバックアップしてから張り替え、張った先を記録する
link_dotfile ~/dotfiles/.config/nvim ~/.config/nvim
link_dotfile ~/dotfiles/.config/tmux ~/.config/tmux
link_dotfile ~/dotfiles/.config/starship.toml ~/.config/starship.toml
link_dotfile ~/dotfiles/.config/fd/ignore ~/.config/fd/ignore
link_dotfile ~/dotfiles/.config/lazygit ~/.config/lazygit
link_dotfile ~/dotfiles/.zshrc ~/.zshrc

# オプションアプリのインストールとシンボリックリンク
source "$SCRIPT_DIR/scripts/optional-apps.sh"
select_and_install_optional_apps

# zshをデフォルトシェルに設定 (Linux only - macOS uses builtin zsh)
if [[ "$(uname -s)" == "Linux" ]]; then
  ZSH_PATH=$(which zsh)
  # $SHELL は環境変数なので実際のログインシェルはpasswdから読む
  CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
  if [ -n "$ZSH_PATH" ] && [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    if ! grep -qxF "$ZSH_PATH" /etc/shells; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
      manifest_record etc-shells "$ZSH_PATH"
    fi
    # 元のシェルを控えておく（uninstall時の復帰先）
    manifest_record shell "$CURRENT_SHELL" "$ZSH_PATH"
    chsh -s "$ZSH_PATH"
  fi
fi
