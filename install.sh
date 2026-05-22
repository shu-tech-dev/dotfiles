#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# OS判定してOS別スクリプトを実行
case "$(uname -s)" in
  Darwin)
    echo "==> Running macOS setup..."
    source "$SCRIPT_DIR/scripts/macos.sh"
    ;;
  Linux)
    echo "==> Running Linux setup..."
    source "$SCRIPT_DIR/scripts/linux.sh"
    ;;
  *)
    echo "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

# 共通処理
echo "==> Running common setup..."
source "$SCRIPT_DIR/scripts/common.sh"

echo "Done! Restart terminal to apply all changes."
