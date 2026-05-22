#!/bin/bash

# ツール定義JSONのパス（install.shで定義されたSCRIPT_DIRを参照）
TOOLS_JSON="$SCRIPT_DIR/packages/ai-tools.json"

# インストール済みかどうかをインストール方法別にチェック
_is_installed() {
  local pkg=$1 method=$2

  case "$method" in
    brew)
      brew list "$pkg" &>/dev/null 2>&1
      ;;
    npm:*)
      # パッケージ名はmethod文字列から "npm:" プレフィックスを除去して取得
      npm list -g --depth=0 "${method#npm:}" &>/dev/null 2>&1
      ;;
    *)
      # brew/npm以外はコマンドの存在で判定
      command -v "$pkg" &>/dev/null
      ;;
  esac
}

# インストール方法に応じてツールをインストール
_install_tool() {
  local pkg=$1 method=$2

  case "$method" in
    brew)
      brew install "$pkg"
      ;;
    npm:*)
      npm install -g "${method#npm:}"
      ;;
    curl:*)
      # インストーラースクリプトをダウンロードして実行
      curl -fsSL "${method#curl:}" | bash
      ;;
    *)
      echo "Unknown install method: $method"
      return 1
      ;;
  esac
}

# fzfでインタラクティブにツールを選択してインストール
select_and_install_ai_tools() {
  echo ""
  echo "==> Installing AI tools"

  # 標準入力がターミナルでない場合（CI・パイプ等）はスキップ
  if ! [ -t 0 ]; then
    echo "Non-interactive mode: skipping AI tools installation"
    return
  fi

  # jqがないとJSONを読めないのでスキップ
  if ! command -v jq &>/dev/null; then
    echo "jq not found. Skipping AI tools installation"
    return
  fi

  # JSONからfzf用の表示リストを生成（"pkg  name — desc" 形式）
  local items
  items=$(jq -r '.[] | "\(.pkg)  \(.name) — \(.desc)"' "$TOOLS_JSON")

  # fzfがない場合は全ツールを一括インストール
  if ! command -v fzf &>/dev/null; then
    echo "fzf not found. Installing all AI tools..."
    jq -r '.[] | "\(.pkg) \(.method)"' "$TOOLS_JSON" | while read -r pkg method; do
      _install_tool "$pkg" "$method"
    done
    return
  fi

  # fzfでインタラクティブ選択（複数選択可）
  local selected
  selected=$(echo "$items" | fzf \
    --multi \
    --prompt="AI tools > " \
    --header="[Space] toggle  [Enter] install  [Esc] skip" \
    --height=~60% \
    --border=rounded \
    --marker="✓")

  # Escまたは未選択でスキップ
  if [ -z "$selected" ]; then
    echo "Skipped AI tools installation"
    return
  fi

  echo ""
  while IFS= read -r line; do
    local pkg method
    # 行頭のパッケージ名を取得
    pkg=$(awk '{print $1}' <<< "$line")
    # JSONからパッケージ名に対応するインストール方法を取得
    method=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .method' "$TOOLS_JSON")

    if _is_installed "$pkg" "$method"; then
      echo "  ✓ $pkg is already installed"
    else
      echo "  → Installing $pkg..."
      _install_tool "$pkg" "$method"
    fi
  done <<< "$selected"

  echo ""
  echo "AI tools installation complete"
}
