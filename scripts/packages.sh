#!/bin/bash

# パッケージのインストール方式を定義する唯一の場所。
# install.sh・uninstall.sh・upgrade.sh がこのファイルを読む。
#
# 「入れる」「消す」「上げる」「入っているか」を method ごとに1箇所へ集めてあるのは、
# install 側だけ直して uninstall 側を忘れる取りこぼしを防ぐため。
# 実際、以前は ai-tools.sh に brew-cask が無く、cask を brew として記録した結果
# uninstall で永久に外れない状態になっていた。
#
#   method         manifest型   入れる                     消す                       上げる
#   brew           brew         brew install PKG           brew uninstall PKG         brew upgrade PKG
#   brew-cask      cask         brew install --cask PKG    brew uninstall --cask PKG  brew upgrade --cask PKG
#   npm:PKG        npm          npm install -g PKG         npm uninstall -g PKG       npm install -g PKG@latest
#   curl:URL       file         curl URL | bash            paths を削除                curl URL | bash（再実行）
#   archive:URL    file         zip を展開して配置          paths を削除                zip を展開して配置（再実行）
#
# curl / archive は配布元が独自にファイルを撒くので、消すべきものを
# JSON の paths に宣言させる。宣言があるので manual 送りにしなくて済む。

# ---------------------------------------------------------------- プラットフォーム

# 現在のプラットフォームを返す（macos / linux / wsl）
pkg_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      # /proc/version に microsoft が含まれる場合は WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

# ------------------------------------------------------------------ インストール

# pkg_is_installed PKG METHOD — 入っていれば 0
pkg_is_installed() {
  local pkg=$1 method=$2

  case "$method" in
    brew)      brew list --formula "$pkg" &>/dev/null ;;
    brew-cask) brew list --cask "$pkg" &>/dev/null ;;
    npm:*)     npm list -g --depth=0 "${method#npm:}" &>/dev/null ;;
    *)         command -v "$pkg" &>/dev/null ;;
  esac
}

# JSON の paths に宣言された成果物を file として記録する。
# 宣言が無ければ 1 を返す（呼び出し側が警告できるように）。
_pkg_record_paths() {
  local json=$1 pkg=$2 path found=1

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    manifest_record file "$(eval echo "$path")"
    found=0
  done < <(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .paths // [] | .[]' "$json")

  return $found
}

# archive:URL 用。zip を落として paths の1つ目へ配置する。
# 展開に失敗したとき配置先に0バイトのファイルを残さないよう、
# 一時ディレクトリで組み立ててから install で移す。
_pkg_install_archive() {
  local url=$1 json=$2 pkg=$3 dest tmp

  dest=$(eval echo "$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .paths[0]' "$json")")
  tmp=$(mktemp -d)

  curl -fsSL -o "$tmp/archive.zip" "$url"
  unzip -p "$tmp/archive.zip" "$(basename "$dest")" > "$tmp/$(basename "$dest")"
  install -Dm755 "$tmp/$(basename "$dest")" "$dest"
  rm -rf "$tmp"
}

# pkg_install PKG METHOD JSON — 入れてマニフェストに記録する
pkg_install() {
  local pkg=$1 method=$2 json=$3

  # 独自インストーラは配置先が PATH に無いと profile を書き換えてくる。
  # codex の add_to_path() は BIN_DIR が PATH にあれば何もせず戻るので、
  # 先に通しておいて書き込みを抑止する（.zshrc 側で元々通しているパス）。
  # 併せて、入れた直後の command -v が新しいコマンドを見つけられるようになる。
  export PATH="$HOME/.local/bin:$PATH"

  case "$method" in
    brew)
      brew install "$pkg" && manifest_record brew "$pkg"
      ;;
    brew-cask)
      brew install --cask "$pkg" && manifest_record cask "$pkg"
      ;;
    npm:*)
      npm install -g "${method#npm:}" && manifest_record npm "${method#npm:}"
      ;;
    curl:*)
      curl -fsSL "${method#curl:}" | bash
      _pkg_record_paths "$json" "$pkg" ||
        echo "  ! $pkg: paths 未宣言のため uninstall で削除できません" >&2
      ;;
    archive:*)
      _pkg_install_archive "${method#archive:}" "$json" "$pkg"
      _pkg_record_paths "$json" "$pkg" ||
        echo "  ! $pkg: paths 未宣言のため uninstall で削除できません" >&2
      ;;
    *)
      echo "Unknown install method: $method" >&2
      return 1
      ;;
  esac
}

# ------------------------------------------------------------------ アップグレード

# pkg_upgrade PKG METHOD JSON — 入っているものを最新にする。run 経由なので --dry-run も効く。
# 入っているかの判定は呼び出し側（pkg_is_installed）で行う。
pkg_upgrade() {
  local pkg=$1 method=$2 json=$3

  # pkg_install と同じ理由で、独自インストーラに profile を書き換えさせない
  export PATH="$HOME/.local/bin:$PATH"

  case "$method" in
    brew)      run brew upgrade "$pkg" ;;
    brew-cask) run brew upgrade --cask "$pkg" ;;
    npm:*)     run npm install -g "${method#npm:}@latest" ;;
    # 独自インストーラ・zip 配布はバージョン確認の手段が無いので、入れ直して最新にする
    curl:*)    run bash -c "curl -fsSL '${method#curl:}' | bash" ;;
    archive:*) run _pkg_install_archive "${method#archive:}" "$json" "$pkg" ;;
    *)
      echo "Unknown install method: $method" >&2
      return 1
      ;;
  esac
}

# --------------------------------------------------------------------- 選択UI

# 現在のプラットフォーム向けのエントリだけを絞り込む jq フィルタ。
# platforms が無いエントリは全プラットフォーム対象とみなす。
_pkg_platform_filter() {
  echo '.[] | select(.platforms == null or (.platforms | index($p) != null))'
}

# pkg_install_entry JSON PKG [POST_HOOK]
# JSON からエントリを引いて、未導入なら入れる。POST_HOOK があれば pkg 名を渡して呼ぶ。
pkg_install_entry() {
  local json=$1 pkg=$2 post_hook=${3:-} method

  method=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .method' "$json")

  # 既に入っているものは触らない（記録もしないので uninstall の対象外になる）
  if pkg_is_installed "$pkg" "$method"; then
    echo "  ✓ $pkg is already installed"
  else
    echo "  → Installing $pkg..."
    pkg_install "$pkg" "$method" "$json"
  fi

  [ -n "$post_hook" ] && "$post_hook" "$json" "$pkg"
  return 0
}

# pkg_select_and_install JSON LABEL [POST_HOOK]
# プラットフォームに合うものを fzf で選ばせて入れる。
# fzf が無ければ全部入れる。非対話や jq 不在ならスキップする。
pkg_select_and_install() {
  local json=$1 label=$2 post_hook=${3:-}
  local platform items selected line pkg

  echo ""
  echo "==> Installing $label"

  # 標準入力がターミナルでない場合（CI・パイプ等）はスキップ
  if ! [ -t 0 ]; then
    echo "Non-interactive mode: skipping $label installation"
    return
  fi

  if ! command -v jq &>/dev/null; then
    echo "jq not found. Skipping $label installation"
    return
  fi

  platform=$(pkg_platform)
  items=$(jq -r --arg p "$platform" "$(_pkg_platform_filter) | \"\(.pkg)  \(.name) — \(.desc)\"" "$json")

  if [ -z "$items" ]; then
    echo "No $label available for this platform ($platform)"
    return
  fi

  if ! command -v fzf &>/dev/null; then
    echo "fzf not found. Installing all $label..."
    selected="$items"
  else
    selected=$(echo "$items" | fzf \
      --multi \
      --prompt="$label > " \
      --header="[Space] toggle  [Enter] install  [Esc] skip" \
      --height=~60% \
      --border=rounded \
      --marker="✓")

    if [ -z "$selected" ]; then
      echo "Skipped $label installation"
      return
    fi
  fi

  echo ""
  while IFS= read -r line; do
    pkg=$(awk '{print $1}' <<< "$line")
    [ -n "$pkg" ] && pkg_install_entry "$json" "$pkg" "$post_hook"
  done <<< "$selected"

  echo ""
  echo "$label installation complete"
}

# pkg_install_required JSON
# 選択させずに、プラットフォームに合うものを全部入れる。
# win32yank のように「その環境では必須」なものに使う。
pkg_install_required() {
  local json=$1 platform pkg

  command -v jq &>/dev/null || return 0

  platform=$(pkg_platform)
  while IFS= read -r pkg; do
    [ -n "$pkg" ] && pkg_install_entry "$json" "$pkg"
  done < <(jq -r --arg p "$platform" "$(_pkg_platform_filter) | .pkg" "$json")
}

# ------------------------------------------------------------------ アンインストール

# マニフェスト型ごとの表示名
pkg_type_label() {
  case "$1" in
    brew) echo "brew formulae" ;;
    cask) echo "brew casks" ;;
    npm)  echo "global npm packages" ;;
    file) echo "files installed by dotfiles" ;;
    *)    echo "$1" ;;
  esac
}

# pkg_type_exists TYPE VALUE — まだ残っていれば 0
pkg_type_exists() {
  case "$1" in
    brew) brew list --formula "$2" &>/dev/null ;;
    cask) brew list --cask "$2" &>/dev/null ;;
    npm)  npm list -g --depth=0 "$2" &>/dev/null ;;
    file) [ -e "$2" ] ;;
    *)    return 1 ;;
  esac
}

# pkg_type_remove TYPE VALUE — 実際に消す。run 経由なので --dry-run も効く。
pkg_type_remove() {
  case "$1" in
    # --ignore-dependencies は付けない。
    # 他が依存していれば brew 側が拒否してくれるので、それを安全弁として使う。
    brew) run brew uninstall "$2" ;;
    cask) run brew uninstall --cask "$2" ;;
    npm)  run npm uninstall -g "$2" ;;
    file)
      # 独自インストーラはディレクトリごと置くこともあるので両対応にする
      if [ -d "$2" ] && [ ! -L "$2" ]; then
        run rm -rf "$2"
      else
        run rm -f "$2"
      fi
      ;;
    *) return 1 ;;
  esac
}

# pkg_type_requires TYPE — その型を扱うのに必要なコマンドが無ければ 1
pkg_type_requires() {
  case "$1" in
    brew | cask) command -v brew &>/dev/null ;;
    npm)         command -v npm &>/dev/null ;;
    *)           return 0 ;;
  esac
}
