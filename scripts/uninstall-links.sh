#!/bin/bash

# Tier: links — dotfiles由来のシンボリックリンク・rc追記・TPM を取り除き、
# インストール時に退避した既存ファイルを書き戻す。

# ~/dotfiles を指すシンボリックリンクだけを削除する。
# 実ファイル・実ディレクトリは絶対に消さない（元から在ったものの可能性があるため）。
_remove_dotfiles_symlink() {
  local path=$1 resolved

  if [ ! -L "$path" ]; then
    [ -e "$path" ] && skip "$path (real file/directory — not a dotfiles symlink)"
    return
  fi

  resolved=$(resolve_path "$path")
  case "$resolved" in
    "$DOTFILES_DIR" | "$DOTFILES_DIR"/*)
      step "removing symlink $path"
      run rm -f "$path"
      ;;
    *)
      skip "$path -> $resolved (points outside $DOTFILES_DIR)"
      ;;
  esac
}

# マニフェストが無い場合の候補: install.sh が張りうるリンクの既知の一覧
_fallback_symlink_candidates() {
  local p
  for p in \
    "$HOME/.config/nvim" \
    "$HOME/.config/tmux" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/fd/ignore" \
    "$HOME/.zshrc" \
    "$HOME/.config/ghostty" \
    "$HOME/.config/karabiner/karabiner.json"; do
    # dotfilesを指すリンクだけを候補に出す
    if [ -L "$p" ]; then
      case "$(resolve_path "$p")" in
        "$DOTFILES_DIR" | "$DOTFILES_DIR"/*) echo "$p" ;;
      esac
    fi
  done
}

remove_symlinks() {
  section "Removing dotfiles symlinks"

  local targets path
  targets=$(resolve_targets symlink "dotfiles symlinks" "$(_fallback_symlink_candidates)")

  if [ -z "$targets" ]; then
    skip "no symlinks to remove"
    return
  fi

  while IFS= read -r path; do
    [ -n "$path" ] && _remove_dotfiles_symlink "$path"
  done <<< "$targets"
}

# rcファイルに追記した行を取り除く（マニフェストに記録がある行のみ）
remove_rc_lines() {
  section "Removing lines added to shell rc files"

  local file line tmp found=0

  while IFS=$'\t' read -r file line; do
    [ -n "$file" ] && [ -f "$file" ] || continue
    grep -qxF "$line" "$file" || continue
    found=1
    step "removing from $file: $line"
    if [ "$DRY_RUN" = "1" ]; then
      continue
    fi
    tmp=$(mktemp)
    grep -vxF "$line" "$file" > "$tmp"
    # 元のパーミッション・inodeを保つため中身だけ差し替える
    cat "$tmp" > "$file"
    rm -f "$tmp"
  done < <(manifest_pairs rcline)

  if [ "$found" = "0" ]; then
    if [ "$MANIFEST_MODE" = "manifest" ]; then
      skip "no recorded rc lines remain"
    else
      skip "no install record — check ~/.bashrc and ~/.zprofile for brew shellenv lines by hand"
    fi
  fi
}

remove_tpm() {
  section "Removing tmux plugin manager"

  local tpm="$HOME/.tmux/plugins/tpm"

  if [ ! -d "$tpm" ]; then
    skip "$tpm not present"
    return
  fi

  if [ "$MANIFEST_MODE" = "manifest" ] && ! manifest_has tpm "$tpm"; then
    skip "$tpm (not installed by dotfiles)"
    return
  fi

  if [ "$MANIFEST_MODE" = "fallback" ]; then
    confirm "remove $tpm? (no install record — may have pre-existed)" || return
  fi

  step "removing $tpm"
  run rm -rf "$tpm"

  # TPMが入れたプラグイン本体は残るので明示的に伝える
  if [ -d "$HOME/.tmux/plugins" ]; then
    local remaining
    remaining=$(find "$HOME/.tmux/plugins" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$remaining" = "0" ]; then
      run rmdir "$HOME/.tmux/plugins" "$HOME/.tmux" 2>/dev/null
    else
      log "  · $remaining tmux plugin(s) left in ~/.tmux/plugins — remove by hand if unwanted"
    fi
  fi
}

# インストール時に退避した既存ファイルを元の場所へ戻す
restore_backups() {
  section "Restoring files backed up at install time"

  local target dest found=0

  while IFS=$'\t' read -r target dest; do
    [ -n "$target" ] || continue
    found=1
    if [ ! -e "$dest" ]; then
      warn "backup missing: $dest"
      continue
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      skip "restore $target (something is already there)"
      continue
    fi
    step "restoring $target from $dest"
    run cp -a "$dest" "$target"
  done < <(manifest_pairs backup)

  [ "$found" = "0" ] && skip "nothing was backed up"
  return 0
}

uninstall_links() {
  remove_symlinks
  restore_backups
  remove_rc_lines
  remove_tpm
}
