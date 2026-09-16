#!/bin/bash

# dotfiles が入れる対象のパッケージ・プラグインを最新にする。
#
# 原則: 「入っているもの」だけを上げ、入っていないものを新たに入れることはしない
# （入れるのは install.sh の役割）。
# 対象の定義は install.sh と同じ packages/ 配下のファイルと packages.sh を参照する。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR="$SCRIPT_DIR"

DRY_RUN=0
TIERS=()

usage() {
  cat << 'EOF'
Usage: ./upgrade.sh [tiers] [options]

Tiers (pick one or more; omit to choose interactively):
  --packages   Brewfile formulae (and their dependencies), casks / npm / installers in packages/*.json
  --nvim       lazy.nvim plugins, nvim-treesitter parsers, Mason packages
  --tmux       tmux plugins installed with TPM
  --node       Node.js LTS via nvm
  --all        every tier above

Options:
  -n, --dry-run   show what would happen without changing anything
  -h, --help      show this help

Only things that are already installed are upgraded; nothing new is installed.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --packages) TIERS+=(packages) ;;
    --nvim) TIERS+=(nvim) ;;
    --tmux) TIERS+=(tmux) ;;
    --node) TIERS+=(node) ;;
    --all) TIERS=(packages nvim tmux node) ;;
    -n | --dry-run) DRY_RUN=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

export DRY_RUN

source "$SCRIPT_DIR/scripts/packages.sh"
# run / section / step などの表示・実行ヘルパーは uninstall と共通のものを使う
source "$SCRIPT_DIR/scripts/uninstall-common.sh"

# ------------------------------------------------------------------ packages

upgrade_brew_formulae() {
  section "Upgrading brew formulae (Brewfile and their dependencies)"

  command -v brew &>/dev/null || {
    skip "brew not found"
    return
  }

  local listed targets outdated upgrades

  listed=$(
    sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES_DIR/packages/Brewfile" |
      while IFS= read -r p; do
        brew list --formula "$p" &>/dev/null && echo "$p"
      done
  )
  [ -n "$listed" ] || {
    skip "no Brewfile formulae are installed"
    return
  }

  # neovim が使う luajit のように、Brewfile に書いていない依存が古いまま残ると不具合の元になるので一緒に上げる。
  # --installed を付けると最新でない依存が除外されてしまうため付けず、outdated との共通部分を取る。
  # shellcheck disable=SC2086
  targets=$({
    echo "$listed"
    brew deps --union --formula $listed
  } | sort -u)
  outdated=$(brew outdated --formula --quiet 2>/dev/null | sort -u)
  upgrades=$(comm -12 <(echo "$targets") <(echo "$outdated"))

  [ -n "$upgrades" ] || {
    skip "everything is up to date"
    return
  }

  echo "$upgrades" | sed 's/^/  · /'
  # shellcheck disable=SC2086
  run brew upgrade --formula $upgrades
}

upgrade_json_tools() {
  section "Upgrading tools listed in packages/*.json"

  command -v jq &>/dev/null || {
    skip "jq not found"
    return
  }

  local json platform pkg method found=0
  platform=$(pkg_platform)

  for json in tools.json ai-tools.json optional-apps.json; do
    json="$DOTFILES_DIR/packages/$json"
    # brew や curl | bash が標準入力を読んでもループの入力を食わないよう、fd 3 から読む
    while IFS=$'\t' read -r -u 3 pkg method; do
      [ -n "$pkg" ] || continue
      pkg_is_installed "$pkg" "$method" || continue
      found=1
      step "$pkg ($method)"
      pkg_upgrade "$pkg" "$method" "$json" || warn "$pkg: upgrade failed"
    done 3< <(jq -r --arg p "$platform" "$(_pkg_platform_filter) | [.pkg, .method] | @tsv" "$json")
  done

  [ "$found" = "1" ] || skip "none of them are installed"
}

upgrade_packages() {
  upgrade_brew_formulae
  upgrade_json_tools
}

# ---------------------------------------------------------------------- nvim

upgrade_nvim() {
  section "Upgrading Neovim plugins, treesitter parsers and Mason packages"

  command -v nvim &>/dev/null || {
    skip "nvim not found"
    return
  }

  run nvim --headless -c "luafile $DOTFILES_DIR/scripts/upgrade-nvim.lua"

  # lazy-lock.json の更新はコミットせず、差分を確認してもらう
  if [ "$DRY_RUN" = "0" ] && ! git -C "$DOTFILES_DIR" diff --quiet -- .config/nvim/lazy-lock.json; then
    log "  lazy-lock.json was updated. Review and commit it:"
    log "    git -C $DOTFILES_DIR diff .config/nvim/lazy-lock.json"
  fi
}

# ---------------------------------------------------------------------- tmux

upgrade_tmux() {
  section "Upgrading tmux plugins (TPM)"

  local updater="$HOME/.tmux/plugins/tpm/bin/update_plugins"
  [ -x "$updater" ] || {
    skip "TPM not installed"
    return
  }

  run "$updater" all
}

# ---------------------------------------------------------------------- node

upgrade_node() {
  section "Upgrading Node.js LTS (nvm)"

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] || {
    skip "nvm not installed"
    return
  }
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  local current latest
  current=$(nvm version default)
  latest=$(nvm version-remote --lts)

  [ "$current" != "$latest" ] || {
    skip "Node.js $current is already the latest LTS"
    return
  }

  step "Node.js $current -> $latest"
  # グローバル npm パッケージを新しいバージョンへ引き継ぐ。古いバージョンは消さずに残す
  run nvm install --lts --reinstall-packages-from="$current"
}

# ------------------------------------------------------------------------ main

# ティア未指定なら対話で選ばせる
select_tiers() {
  local items selected
  items=$(
    cat << 'EOF'
packages  Brewfile formulae (+ deps), casks / npm / installers in packages/*.json
nvim      lazy.nvim plugins, treesitter parsers, Mason packages
tmux      tmux plugins (TPM)
node      Node.js LTS (nvm)
EOF
  )

  if command -v fzf &>/dev/null && has_tty; then
    selected=$(echo "$items" | fzf --multi \
      --prompt="Upgrade > " \
      --header="[Space] toggle  [Enter] run  [Esc] abort" \
      --height=~40% \
      --border=rounded \
      --marker="✓")
  else
    echo "fzf not found. Specify tiers explicitly (see --help)." >&2
    exit 1
  fi

  [ -n "$selected" ] || {
    echo "Nothing selected. Aborted."
    exit 0
  }
  while IFS= read -r line; do
    TIERS+=("$(awk '{print $1}' <<< "$line")")
  done <<< "$selected"
}

[ ${#TIERS[@]} -eq 0 ] && select_tiers

echo "==> dotfiles upgrade"
[ "$DRY_RUN" = "1" ] && echo "    dry-run: no changes will be made"
echo "    tiers: ${TIERS[*]}"

for tier in "${TIERS[@]}"; do
  case "$tier" in
    packages) upgrade_packages ;;
    nvim) upgrade_nvim ;;
    tmux) upgrade_tmux ;;
    node) upgrade_node ;;
  esac
done

echo ""
echo "Done."
