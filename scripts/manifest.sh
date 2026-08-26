#!/bin/bash

# インストール実績のマニフェスト。
#
# install.sh は「実際に自分が新規導入したもの」だけをここに追記し、
# uninstall.sh はここに記録があるものだけを削除する。
# これにより「元から入っていたもの」を消さずに済む。
#
# 形式: TAB区切りの追記専用テキスト
#   TYPE <TAB> VALUE <TAB> EXTRA
#
# JSONではなくTSVなのは、apt導入段階ではまだjqが入っていないため。

DOTFILES_STATE_DIR="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
MANIFEST_FILE="$DOTFILES_STATE_DIR/manifest.tsv"
BACKUP_DIR="$DOTFILES_STATE_DIR/backups"

# ---------------------------------------------------------------- 記録・参照

manifest_init() {
  mkdir -p "$DOTFILES_STATE_DIR" "$BACKUP_DIR"
  [ -f "$MANIFEST_FILE" ] || : > "$MANIFEST_FILE"
  manifest_record run "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

# manifest_record TYPE VALUE [EXTRA]
manifest_record() {
  local type=$1 value=$2 extra=${3:-}
  mkdir -p "$DOTFILES_STATE_DIR"
  printf '%s\t%s\t%s\n' "$type" "$value" "$extra" >> "$MANIFEST_FILE"
}

# manifest_has TYPE VALUE — 記録があれば 0
manifest_has() {
  local type=$1 value=$2
  [ -f "$MANIFEST_FILE" ] || return 1
  awk -F'\t' -v t="$type" -v v="$value" '$1==t && $2==v {f=1} END{exit !f}' "$MANIFEST_FILE"
}

# manifest_values TYPE — VALUE を重複なしで列挙
manifest_values() {
  local type=$1
  [ -f "$MANIFEST_FILE" ] || return 0
  awk -F'\t' -v t="$type" '$1==t {print $2}' "$MANIFEST_FILE" | awk '!seen[$0]++'
}

# manifest_pairs TYPE — "VALUE<TAB>EXTRA" を重複なしで列挙
manifest_pairs() {
  local type=$1
  [ -f "$MANIFEST_FILE" ] || return 0
  awk -F'\t' -v t="$type" '$1==t {print $2"\t"$3}' "$MANIFEST_FILE" | awk '!seen[$0]++'
}

# ------------------------------------------------------ 退避・シンボリックリンク

# 既存の実体を退避して記録する。
# シンボリックリンクは実体を持たないので対象外。
backup_existing() {
  local target=$1 stamp dest

  [ -e "$target" ] || return 0
  [ -L "$target" ] && return 0

  stamp=$(date +%Y%m%d-%H%M%S)
  dest="$BACKUP_DIR/$stamp/$(basename "$target")"
  mkdir -p "$(dirname "$dest")"
  cp -a "$target" "$dest"
  manifest_record backup "$target" "$dest"
  echo "  ↳ backed up $target -> $dest"
}

# dotfiles配下へのシンボリックリンクを安全に張る。
#   - 既存の実体はバックアップしてから退ける
#     （実ディレクトリが残っていると ln -sfn がその中にリンクを作ってしまう）
#   - 張ったリンクをマニフェストに記録する
link_dotfile() {
  local src dst
  src=$(eval echo "$1")
  dst=$(eval echo "$2")

  # 既に同じリンクなら記録だけ更新して終わり
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    manifest_record symlink "$dst" "$src"
    return 0
  fi

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    backup_existing "$dst"
    rm -rf "$dst"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  manifest_record symlink "$dst" "$src"
}

# rcファイルへの追記を記録付きで行う。
# match_pattern に一致する行が既にあれば何もしない。
append_rc_line() {
  local file=$1 line=$2 match_pattern=${3:-}

  touch "$file"
  if [ -n "$match_pattern" ]; then
    grep -q "$match_pattern" "$file" && return 0
  else
    grep -qxF "$line" "$file" && return 0
  fi

  echo "$line" >> "$file"
  manifest_record rcline "$file" "$line"
}

# ------------------------------------------------------------ パッケージ導入

# aptパッケージを導入し、実際に新規追加されたものだけを記録する
apt_install_tracked() {
  local pkgs=("$@") missing=() p

  for p in "${pkgs[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "ok installed"; then
      missing+=("$p")
    fi
  done

  [ ${#missing[@]} -eq 0 ] && return 0

  sudo apt-get install -y "${missing[@]}"
  for p in "${missing[@]}"; do
    manifest_record apt "$p"
  done
}

_brew_formula_list() { brew list --formula -1 2>/dev/null | sort; }
_brew_cask_list() { brew list --cask -1 2>/dev/null | sort; }

# brew bundle を実行し、前後の差分から新規導入分だけを記録する。
# 明示的に要求されたもの(brew)と、依存で連れてこられたもの(brew-dep)を分けて記録し、
# アンインストール時は前者だけを対象にする。
run_brew_bundle() {
  local brewfile=$1 before_f before_c requested f c

  before_f=$(_brew_formula_list)
  before_c=$(_brew_cask_list)

  brew bundle --file "$brewfile"

  requested=$(brew list --installed-on-request --formula -1 2>/dev/null | sort)

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if grep -qxF "$f" <<< "$requested"; then
      manifest_record brew "$f"
    else
      manifest_record brew-dep "$f"
    fi
  done < <(comm -13 <(echo "$before_f") <(_brew_formula_list))

  while IFS= read -r c; do
    [ -n "$c" ] && manifest_record cask "$c"
  done < <(comm -13 <(echo "$before_c") <(_brew_cask_list))
}
