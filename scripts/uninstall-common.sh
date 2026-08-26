#!/bin/bash

# uninstall.sh 共通ヘルパー

DRY_RUN=${DRY_RUN:-0}
ASSUME_YES=${ASSUME_YES:-0}
MANIFEST_MODE=${MANIFEST_MODE:-fallback} # manifest | fallback
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

log() { echo "$@"; }
step() { echo "  → $*"; }
skip() { echo "  · skipped: $*"; }
warn() { echo "  ! $*" >&2; }

section() {
  echo ""
  echo "==> $*"
}

# 実行ラッパー。--dry-run では実行せず内容だけ出す
run() {
  if [ "$DRY_RUN" = "1" ]; then
    echo "  [dry-run] $*"
    return 0
  fi
  "$@"
}

# /dev/tty が本当に端末として使えるか確認する。
# ファイルとして存在するだけでは足りない（CI等では開けても端末ではない）ので、
# 実際に開いた上で -t で判定する。
has_tty() {
  local ok=1
  { exec 3< /dev/tty; } 2>/dev/null || return 1
  [ -t 3 ] && ok=0
  exec 3<&-
  return $ok
}

# y/N 確認。パイプ越しでも聞けるよう /dev/tty から読む
confirm() {
  local prompt=$1 ans
  [ "$ASSUME_YES" = "1" ] && return 0
  if ! has_tty; then
    warn "non-interactive: assuming No for \"$prompt\""
    return 1
  fi
  read -r -p "  ? $prompt [y/N] " ans < /dev/tty
  [[ "$ans" =~ ^[Yy]$ ]]
}

# readlink -f 相当。BSD readlinkに -f が無い環境でも動くよう自前で辿る
resolve_path() {
  local p=$1 t
  while [ -L "$p" ]; do
    t=$(readlink "$p")
    case "$t" in
      /*) p=$t ;;
      *) p=$(dirname "$p")/$t ;;
    esac
  done
  if [ -d "$p" ]; then
    (cd "$p" && pwd)
  else
    echo "$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")"
  fi
}

# 削除対象リストを決める。
#   manifest モード: install.sh が記録したものをそのまま返す
#   fallback モード: 候補を提示してユーザーに選ばせる（既定は何も選ばれていない）
#
# resolve_targets TYPE HEADER CANDIDATES
resolve_targets() {
  local type=$1 header=$2 candidates=$3 c

  if [ "$MANIFEST_MODE" = "manifest" ]; then
    manifest_values "$type"
    return
  fi

  [ -n "$candidates" ] || return 0

  if command -v fzf &>/dev/null && has_tty; then
    echo "$candidates" | fzf --multi \
      --prompt="$header > " \
      --header="[Space] select  [Enter] remove  [Esc] skip — nothing selected by default" \
      --height=~60% \
      --border=rounded \
      --marker="✓"
  else
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      confirm "remove $c?" && echo "$c"
    done <<< "$candidates"
  fi
}
