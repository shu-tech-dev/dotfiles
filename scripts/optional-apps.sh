#!/bin/bash

# オプションアプリ定義JSONのパス
OPTIONAL_APPS_JSON="$SCRIPT_DIR/packages/optional-apps.json"

# 現在のプラットフォームを返す（macos / linux / wsl）
_current_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      # /proc/versionにmicrosoftが含まれる場合はWSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

# インストール済みかどうかをインストール方法別にチェック
_is_installed_optional() {
  local pkg=$1 method=$2

  case "$method" in
    brew | brew-cask)
      brew list "$pkg" &>/dev/null 2>&1
      ;;
    *)
      command -v "$pkg" &>/dev/null
      ;;
  esac
}

# インストール方法に応じてアプリをインストール
_install_optional() {
  local pkg=$1 method=$2

  case "$method" in
    brew)
      brew install "$pkg" && manifest_record brew "$pkg"
      ;;
    brew-cask)
      brew install --cask "$pkg" && manifest_record cask "$pkg"
      ;;
    *)
      echo "Unknown install method: $method"
      return 1
      ;;
  esac
}

# シンボリックリンクを作成（既存の実体は退避され、張った先は記録される）
_symlink_optional() {
  local src=$1 dst=$2

  # JSON側でsymlinkが未定義のエントリはスキップ
  if [ -z "$src" ] || [ "$src" = "null" ]; then
    return 0
  fi

  link_dotfile "$src" "$dst"
}

# fzfでインタラクティブにオプションアプリを選択してインストール
select_and_install_optional_apps() {
  echo ""
  echo "==> Installing optional apps"

  # 標準入力がターミナルでない場合（CI・パイプ等）はスキップ
  if ! [ -t 0 ]; then
    echo "Non-interactive mode: skipping optional apps installation"
    return
  fi

  # jqがないとJSONを読めないのでスキップ
  if ! command -v jq &>/dev/null; then
    echo "jq not found. Skipping optional apps installation"
    return
  fi

  # 現在のプラットフォームに対応するアプリのみ抽出
  local platform items
  platform=$(_current_platform)
  items=$(jq -r --arg p "$platform" \
    '.[] | select(.platforms == null or (.platforms | index($p) != null)) | "\(.pkg)  \(.name) — \(.desc)"' \
    "$OPTIONAL_APPS_JSON")

  if [ -z "$items" ]; then
    echo "No optional apps available for this platform ($platform)"
    return
  fi

  # fzfがない場合はプラットフォーム対応アプリを一括インストール
  if ! command -v fzf &>/dev/null; then
    echo "fzf not found. Installing all optional apps..."
    jq -c --arg p "$platform" \
      '.[] | select(.platforms == null or (.platforms | index($p) != null))' \
      "$OPTIONAL_APPS_JSON" | while read -r entry; do
      local pkg method src dst
      pkg=$(echo "$entry" | jq -r '.pkg')
      method=$(echo "$entry" | jq -r '.method')
      src=$(echo "$entry" | jq -r '.symlink_src')
      dst=$(echo "$entry" | jq -r '.symlink_dst')
      # 既に入っているものは触らない（記録もしないのでuninstallの対象外になる）
      _is_installed_optional "$pkg" "$method" || _install_optional "$pkg" "$method"
      _symlink_optional "$src" "$dst"
    done
    return
  fi

  # fzfでインタラクティブ選択（複数選択可）
  local selected
  selected=$(echo "$items" | fzf \
    --multi \
    --prompt="Optional apps > " \
    --header="[Space] toggle  [Enter] install  [Esc] skip" \
    --height=~60% \
    --border=rounded \
    --marker="✓")

  # Escまたは未選択でスキップ
  if [ -z "$selected" ]; then
    echo "Skipped optional apps installation"
    return
  fi

  echo ""
  while IFS= read -r line; do
    local pkg method src dst
    # 行頭のパッケージ名を取得
    pkg=$(awk '{print $1}' <<< "$line")
    # JSONからパッケージ名に対応する情報を取得
    method=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .method' "$OPTIONAL_APPS_JSON")
    src=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .symlink_src' "$OPTIONAL_APPS_JSON")
    dst=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .symlink_dst' "$OPTIONAL_APPS_JSON")

    if _is_installed_optional "$pkg" "$method"; then
      echo "  ✓ $pkg is already installed"
    else
      echo "  → Installing $pkg..."
      _install_optional "$pkg" "$method"
    fi

    echo "  → Linking $pkg config..."
    _symlink_optional "$src" "$dst"
  done <<< "$selected"

  echo ""
  echo "Optional apps installation complete"
}
