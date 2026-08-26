#!/bin/bash

# Tier: packages / node — brew formula・cask・グローバルnpm・nvm/Node を取り除く。
# Homebrew本体はシステム系なので uninstall-system.sh 側で扱う。

# マニフェストが無い場合の候補: Brewfile と ai-tools.json に載っていて、
# かつ現在インストール済みのものだけを出す
_fallback_brew_candidates() {
  {
    sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES_DIR/packages/Brewfile" 2>/dev/null
    if command -v jq &>/dev/null; then
      jq -r '.[] | select(.method == "brew") | .pkg' \
        "$DOTFILES_DIR/packages/ai-tools.json" 2>/dev/null
    fi
  } | awk '!seen[$0]++' | while IFS= read -r p; do
    brew list --formula "$p" &>/dev/null && echo "$p"
  done
}

_fallback_cask_candidates() {
  command -v jq &>/dev/null || return 0
  jq -r '.[] | select(.method == "brew-cask") | .pkg' \
    "$DOTFILES_DIR/packages/optional-apps.json" 2>/dev/null | while IFS= read -r p; do
    brew list --cask "$p" &>/dev/null && echo "$p"
  done
}

_fallback_npm_candidates() {
  command -v jq &>/dev/null || return 0
  jq -r '.[] | select(.method | startswith("npm:")) | .method | sub("^npm:"; "")' \
    "$DOTFILES_DIR/packages/ai-tools.json" 2>/dev/null | while IFS= read -r p; do
    npm list -g --depth=0 "$p" &>/dev/null && echo "$p"
  done
}

uninstall_brew_formulae() {
  section "Uninstalling brew formulae"

  if ! command -v brew &>/dev/null; then
    skip "brew not found"
    return
  fi

  local targets pkg
  targets=$(resolve_targets brew "brew formulae" "$(_fallback_brew_candidates)")

  if [ -z "$targets" ]; then
    skip "no formulae selected"
    return
  fi

  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    if ! brew list --formula "$pkg" &>/dev/null; then
      skip "$pkg (not installed)"
      continue
    fi
    step "uninstalling formula $pkg"
    # --ignore-dependencies は付けない。
    # 他が依存していれば brew 側が拒否してくれるので、それを安全弁として使う。
    run brew uninstall "$pkg" ||
      warn "$pkg left installed (still required by something else)"
  done <<< "$targets"
}

uninstall_brew_casks() {
  section "Uninstalling brew casks"

  if ! command -v brew &>/dev/null; then
    skip "brew not found"
    return
  fi

  local targets pkg
  targets=$(resolve_targets cask "brew casks" "$(_fallback_cask_candidates)")

  if [ -z "$targets" ]; then
    skip "no casks selected"
    return
  fi

  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    if ! brew list --cask "$pkg" &>/dev/null; then
      skip "$pkg (not installed)"
      continue
    fi
    step "uninstalling cask $pkg"
    run brew uninstall --cask "$pkg" || warn "failed to uninstall cask $pkg"
  done <<< "$targets"
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

uninstall_npm_globals() {
  section "Uninstalling global npm packages"

  if ! command -v npm &>/dev/null; then
    skip "npm not found"
    return
  fi

  local targets pkg
  targets=$(resolve_targets npm "global npm packages" "$(_fallback_npm_candidates)")

  if [ -z "$targets" ]; then
    skip "no npm packages selected"
    return
  fi

  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    step "uninstalling npm package $pkg"
    run npm uninstall -g "$pkg" || warn "failed to uninstall $pkg"
  done <<< "$targets"
}

# install.sh が自分で決めたパスに置いた実ファイル（win32yank など）を消す
remove_installed_files() {
  local files f
  files=$(manifest_values file)
  [ -n "$files" ] || return 0

  section "Removing files installed by dotfiles"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ ! -e "$f" ]; then
      skip "$f (already gone)"
      continue
    fi
    confirm "remove $f?" || continue
    step "removing $f"
    run rm -f "$f"
  done <<< "$files"
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
  uninstall_brew_formulae
  uninstall_brew_casks
  sweep_brew_orphans
  uninstall_npm_globals
  remove_installed_files
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
