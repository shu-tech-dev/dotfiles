#!/bin/bash

# install.sh の逆操作。
#
# 大原則: 「install.sh が実際に入れたもの」だけを消し、元から入っていたものは触らない。
#
# そのために install.sh は導入したものを ~/.local/state/dotfiles/manifest.tsv に記録する。
#   - 記録がある場合 (manifest モード): 記録されたものだけを消す
#   - 記録が無い場合 (fallback モード): 何が元から在ったか判断できないので、
#     候補を提示してユーザーに選ばせる。既定では何も選ばれていない。
#     システム系はfallbackでは一切触らない。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR="$SCRIPT_DIR"

source "$SCRIPT_DIR/scripts/manifest.sh"

DRY_RUN=0
ASSUME_YES=0
TIERS=()

usage() {
  cat << 'EOF'
Usage: ./uninstall.sh [tiers] [options]

Tiers (pick one or more; omit to choose interactively):
  --links      dotfiles symlinks, rc-file lines, TPM, and restore backed-up files
  --packages   brew formulae/casks and global npm packages installed by dotfiles
  --node       nvm and Node.js versions installed by dotfiles
  --system     apt packages, Homebrew itself, login shell  (manifest only)
  --all        every tier above

Options:
  -n, --dry-run   show what would happen without changing anything
  -y, --yes       answer yes to every confirmation
  -h, --help      show this help

Nothing outside the install record is ever removed without asking, and real files
that are not dotfiles symlinks are never deleted.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --links) TIERS+=(links) ;;
    --packages) TIERS+=(packages) ;;
    --node) TIERS+=(node) ;;
    --system) TIERS+=(system) ;;
    --all) TIERS=(links packages node system) ;;
    -n | --dry-run) DRY_RUN=1 ;;
    -y | --yes) ASSUME_YES=1 ;;
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

# マニフェストの有無でモードを決める
if [ -s "$MANIFEST_FILE" ]; then
  MANIFEST_MODE=manifest
else
  MANIFEST_MODE=fallback
fi

export DRY_RUN ASSUME_YES MANIFEST_MODE

source "$SCRIPT_DIR/scripts/packages.sh"
source "$SCRIPT_DIR/scripts/uninstall-common.sh"
source "$SCRIPT_DIR/scripts/uninstall-links.sh"
source "$SCRIPT_DIR/scripts/uninstall-packages.sh"
source "$SCRIPT_DIR/scripts/uninstall-system.sh"

# ティア未指定なら対話で選ばせる
select_tiers() {
  local items selected
  items=$(
    cat << 'EOF'
links     symlinks, rc lines, TPM, restore backups
packages  brew formulae/casks and global npm packages
node      nvm and Node.js versions
system    apt, Homebrew itself, login shell
EOF
  )

  if command -v fzf &>/dev/null && has_tty; then
    selected=$(echo "$items" | fzf --multi \
      --prompt="Uninstall > " \
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

echo "==> dotfiles uninstall"
if [ "$MANIFEST_MODE" = "manifest" ]; then
  echo "    mode: manifest ($MANIFEST_FILE)"
  echo "          only things install.sh recorded will be removed"
else
  echo "    mode: fallback (no install record found)"
  echo "          nothing can be proven to be ours, so every removal is opt-in"
  echo "          the --system tier is disabled in this mode"
fi
[ "$DRY_RUN" = "1" ] && echo "    dry-run: no changes will be made"
echo "    tiers: ${TIERS[*]}"

for tier in "${TIERS[@]}"; do
  case "$tier" in
    links) uninstall_links ;;
    packages) uninstall_packages ;;
    node) uninstall_node ;;
    system) uninstall_system ;;
  esac
done

echo ""
echo "Done."
if [ "$MANIFEST_MODE" = "manifest" ] && [ "$DRY_RUN" = "0" ]; then
  echo "The install record is kept at $MANIFEST_FILE."
  echo "Backups of files replaced at install time are under $BACKUP_DIR."
fi
echo "The ~/dotfiles repository itself was not touched."
