#!/bin/bash

# オプションアプリの導入。インストール方式の実装は packages.sh 側にある。
# こちらは設定ファイルのシンボリックリンクを張る後処理だけを追加で持つ。

OPTIONAL_APPS_JSON="$SCRIPT_DIR/packages/optional-apps.json"

# インストール後に設定ファイルのシンボリックリンクを張る。
# 既存の実体は退避され、張った先はマニフェストに記録される。
_link_optional_config() {
  local json=$1 pkg=$2 src dst

  src=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .symlink_src // empty' "$json")
  dst=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .symlink_dst // empty' "$json")

  [ -n "$src" ] && [ -n "$dst" ] || return 0

  echo "  → Linking $pkg config..."
  link_dotfile "$src" "$dst"
}

select_and_install_optional_apps() {
  pkg_select_and_install "$OPTIONAL_APPS_JSON" "optional apps" _link_optional_config
}
