#!/bin/bash

# Tier: system — aptパッケージ・Homebrew本体・ログインシェル。
#
# ここは他の用途と共有されている確率が高いので、
# マニフェストに記録があるものに限り、かつ毎回確認を取ってから消す。
# 記録が無い場合（fallbackモード）は何もしない。

_require_record() {
  local what=$1
  if [ "$MANIFEST_MODE" != "manifest" ]; then
    skip "$what (no install record — refusing to guess at system level)"
    return 1
  fi
  return 0
}

# ログインシェルをinstall.sh実行前のものへ戻す
revert_login_shell() {
  section "Reverting login shell"

  local entry from to current
  entry=$(manifest_pairs shell | tail -n 1)

  if [ -z "$entry" ]; then
    skip "login shell (no record of the original shell — leaving it alone)"
    return
  fi

  from=$(cut -f1 <<< "$entry")
  to=$(cut -f2 <<< "$entry")
  current=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)

  if [ "$current" != "$to" ]; then
    skip "login shell is $current, not $to — leaving it alone"
    return
  fi
  if [ ! -x "$from" ]; then
    warn "original shell $from no longer exists — leaving login shell as $current"
    return
  fi

  confirm "revert login shell from $to back to $from?" || return
  step "chsh -s $from"
  run chsh -s "$from"

  # /etc/shells への追記は他ユーザーにも影響しうるので、残しておくのが無難
  local added
  added=$(manifest_values etc-shells)
  [ -n "$added" ] && log "  · left '$added' in /etc/shells (harmless, and other users may rely on it)"
}

remove_apt_packages() {
  section "Removing apt packages"

  command -v apt-get &>/dev/null || {
    skip "apt-get not available"
    return
  }
  _require_record "apt packages" || return

  local pkgs p installed=()
  pkgs=$(manifest_values apt)

  if [ -z "$pkgs" ]; then
    skip "no apt packages recorded"
    return
  fi

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "ok installed" && installed+=("$p")
  done <<< "$pkgs"

  if [ ${#installed[@]} -eq 0 ]; then
    skip "none of the recorded apt packages are still installed"
    return
  fi

  log "  Recorded apt packages still installed: ${installed[*]}"
  log "  Note: build-essential / curl / git are commonly needed by other software."
  confirm "apt-get remove the packages listed above?" || return

  step "apt-get remove ${installed[*]}"
  run sudo apt-get remove -y "${installed[@]}"
}

uninstall_homebrew() {
  section "Uninstalling Homebrew"

  _require_record "Homebrew" || return

  local prefix
  prefix=$(manifest_values homebrew | tail -n 1)

  if [ -z "$prefix" ]; then
    skip "Homebrew was already installed before dotfiles — leaving it alone"
    return
  fi
  if ! command -v brew &>/dev/null; then
    skip "brew not found"
    return
  fi

  log "  This removes Homebrew itself and EVERYTHING still installed through it."
  confirm "run the official Homebrew uninstaller?" || return

  step "running Homebrew uninstall script"
  if [ "$DRY_RUN" = "1" ]; then
    echo "  [dry-run] curl -fsSL .../uninstall.sh | bash"
    return
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
}

uninstall_system() {
  revert_login_shell
  remove_apt_packages
  uninstall_homebrew
}
