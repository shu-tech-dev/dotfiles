#!/bin/bash

# Tier: packages / node — brew formula・cask・グローバルnpm・nvm/Node を取り除く。
# Homebrew本体はシステム系なので uninstall-system.sh 側で扱う。

# マニフェストが無い場合の候補: Brewfile と ai-tools.json に載っていて、
# かつ現在インストール済みのものだけを出す
# マニフェストが無い場合の候補。
# 型ごとに情報源が違う（Brewfile / ai-tools.json / optional-apps.json）ので
# ここだけは型別のままにする。file は推測しようがないので候補を出さない。
_fallback_candidates() {
  command -v jq &>/dev/null || [ "$1" = "brew" ] || return 0

  case "$1" in
    brew)
      {
        sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES_DIR/packages/Brewfile" 2>/dev/null
        if command -v jq &>/dev/null; then
          jq -r '.[] | select(.method == "brew") | .pkg' \
            "$DOTFILES_DIR/packages/ai-tools.json" 2>/dev/null
        fi
      } | awk '!seen[$0]++' | while IFS= read -r p; do
        brew list --formula "$p" &>/dev/null && echo "$p"
      done
      ;;
    cask)
      jq -r '.[] | select(.method == "brew-cask") | .pkg' \
        "$DOTFILES_DIR/packages/optional-apps.json" "$DOTFILES_DIR/packages/ai-tools.json" 2>/dev/null |
        awk '!seen[$0]++' | while IFS= read -r p; do
          brew list --cask "$p" &>/dev/null && echo "$p"
        done
      ;;
    npm)
      jq -r '.[] | select(.method | startswith("npm:")) | .method | sub("^npm:"; "")' \
        "$DOTFILES_DIR/packages/ai-tools.json" 2>/dev/null | while IFS= read -r p; do
        npm list -g --depth=0 "$p" &>/dev/null && echo "$p"
      done
      ;;
  esac
}

# マニフェストに記録されたパッケージを型ごとに削除する。
#
# brew / cask / npm / file は「対象を取る→まだ残っているか確認→消す」で
# 手順が完全に同じなので、違いは packages.sh のテーブルに閉じ込めてある。
# 型ごとに関数を書き分けると、方式を足すたびに install 側と両方を直すことになり、
# 実際それが原因で cask が uninstall から漏れていた。
uninstall_recorded_packages() {
  local type targets value

  for type in brew cask npm file; do
    section "Uninstalling $(pkg_type_label "$type")"

    if ! pkg_type_requires "$type"; then
      skip "required command not found"
      continue
    fi

    targets=$(resolve_targets "$type" "$(pkg_type_label "$type")" "$(_fallback_candidates "$type")")
    if [ -z "$targets" ]; then
      skip "no $(pkg_type_label "$type") selected"
      continue
    fi

    while IFS= read -r value; do
      [ -n "$value" ] || continue
      if ! pkg_type_exists "$type" "$value"; then
        skip "$value (not installed)"
        continue
      fi
      step "removing $value"
      pkg_type_remove "$type" "$value" ||
        warn "$value left in place (still required by something else, or removal failed)"
    done <<< "$targets"
  done
}

# 依存として一緒に入ったformulaは brew autoremove に任せる。
# autoremove は「依存として入り、今は誰にも必要とされていない」ものだけを消すので、
# ユーザーが自分で入れたものには手を出さない。
sweep_brew_orphans() {
  command -v brew &>/dev/null || return 0

  local deps count
  deps=$(manifest_values brew-dep)
  [ -n "$deps" ] || return 0

  count=$(wc -l <<< "$deps" | tr -d ' ')
  section "Dependency sweep"
  log "  $count formula(e) came in as dependencies of the above."
  confirm "run 'brew autoremove' to drop dependencies nothing needs anymore?" || return 0
  run brew autoremove
}

# 独自インストーラで入れたものは削除手順がツール固有なので、案内だけ出す
report_manual_tools() {
  local tools
  tools=$(manifest_values manual)
  [ -n "$tools" ] || return 0

  section "Tools needing manual removal"
  log "  These were installed by their own installer script — remove them yourself:"
  while IFS= read -r t; do
    [ -n "$t" ] && log "    - $t"
  done <<< "$tools"
}

uninstall_packages() {
  uninstall_recorded_packages
  sweep_brew_orphans
  report_manual_tools
}

# ------------------------------------------------------------------ node tier

_installed_node_versions() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  [ -d "$nvm_dir/versions/node" ] || return 0
  find "$nvm_dir/versions/node" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -u
}

uninstall_node() {
  section "Removing nvm / Node.js"

  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [ ! -d "$nvm_dir" ]; then
    skip "$nvm_dir not present"
    return
  fi

  # nvm自体をinstall.shが入れた場合に限り、まるごと消す選択肢を出す
  if manifest_has nvm "$nvm_dir"; then
    if confirm "remove nvm and ALL Node versions under $nvm_dir?"; then
      step "removing $nvm_dir"
      run rm -rf "$nvm_dir"
      return
    fi
    log "  · keeping nvm itself; falling back to per-version removal"
  elif [ "$MANIFEST_MODE" = "manifest" ]; then
    log "  · nvm pre-existed — leaving it installed, removing only recorded Node versions"
  fi

  local versions v
  versions=$(resolve_targets node "Node versions" "$(_installed_node_versions)")

  if [ -z "$versions" ]; then
    skip "no Node versions selected"
    return
  fi

  if [ ! -s "$nvm_dir/nvm.sh" ]; then
    warn "nvm.sh not found at $nvm_dir — cannot uninstall Node versions"
    return
  fi

  while IFS= read -r v; do
    [ -n "$v" ] || continue
    step "uninstalling Node $v"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  [dry-run] nvm uninstall $v"
      continue
    fi
    # nvm はシェル関数なので、サブシェルで読み込んでから呼ぶ
    bash -c 'export NVM_DIR="$1"; . "$NVM_DIR/nvm.sh"; nvm uninstall "$2"' _ "$nvm_dir" "$v" ||
      warn "failed to uninstall Node $v (it may be the version currently in use)"
  done <<< "$versions"
}
