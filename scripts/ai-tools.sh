#!/bin/bash

# AIツールの導入。インストール方式の実装は packages.sh 側にあるので、
# ここは「どのJSONをどのラベルで選ばせるか」だけを持つ。

AI_TOOLS_JSON="$SCRIPT_DIR/packages/ai-tools.json"

select_and_install_ai_tools() {
  pkg_select_and_install "$AI_TOOLS_JSON" "AI tools"
}
