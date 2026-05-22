#!/bin/bash
# dotfiles を公開用ミラーリポジトリに同期する
#
# Usage: ./scripts/sync-public.sh [path/to/dotfiles-public]
#   引数省略時は ~/dotfiles-public を使用

set -e

PUBLIC_DIR="${1:-$HOME/dotfiles-public}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$PUBLIC_DIR/.git" ]; then
  echo "Error: $PUBLIC_DIR is not a git repository"
  echo "First clone the public repo: git clone <url> $PUBLIC_DIR"
  exit 1
fi

# rsync で同期。--exclude='/.git/' でソース・ターゲット双方の .git を保護
rsync -av --delete \
  --exclude='/.git/' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  --exclude='*.swp' \
  --exclude='.env*' \
  "$DOTFILES_DIR/" "$PUBLIC_DIR/"

echo ""
echo "Synced. Review and commit:"
echo "  cd $PUBLIC_DIR"
echo "  git status"
echo "  git add -A && git commit -m 'sync' && git push"
