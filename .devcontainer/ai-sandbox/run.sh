#!/bin/bash
# 選択した AI ツールを Docker サンドボックス内で実行する

set -e

SANDBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SANDBOX_DIR/../.." && pwd)"
TOOLS_JSON="$DOTFILES_DIR/packages/ai-tools.json"
BASE_IMAGE="ai-sandbox-base"
WORKDIR="/workspace/$(basename "$(pwd)")"

# --upgrade フラグでツールをアップグレード
UPGRADE=0
if [ "$1" = "--upgrade" ]; then
  UPGRADE=1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required but not found"
  exit 1
fi

# ベースイメージが未ビルドなら構築
if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
  echo "Building base image..."
  docker build -t "$BASE_IMAGE" "$SANDBOX_DIR"
fi

# 全ツールを fzf でインタラクティブ選択
items=$(jq -r '.[] | "\(.pkg)  \(.name) — \(.desc)"' "$TOOLS_JSON")

if [ -z "$items" ]; then
  echo "No tools found in ai-tools.json"
  exit 1
fi

selected=$(echo "$items" | fzf \
  --prompt="AI tool > " \
  --header="[Enter] launch  [Esc] cancel" \
  --height=~60% \
  --border=rounded)

if [ -z "$selected" ]; then
  echo "Cancelled"
  exit 0
fi

# 選択したツールの情報を取得
pkg=$(awk '{print $1}' <<< "$selected")
tool_json=$(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg)' "$TOOLS_JSON")
method=$(echo "$tool_json" | jq -r '.method')
yolo_cmd=$(echo "$tool_json" | jq -r '.yolo_cmd')
image="ai-sandbox-$pkg"

# --upgrade 時は既存イメージを削除して再ビルドさせる
if [ "$UPGRADE" = "1" ] && docker image inspect "$image" &>/dev/null; then
  echo "Removing existing $pkg image for upgrade..."
  docker rmi "$image" &>/dev/null
fi

# ツールイメージが未ビルドなら動的に Dockerfile を生成して構築
if ! docker image inspect "$image" &>/dev/null; then
  echo "Building $pkg image..."

  case "$method" in
    brew)   install_cmd="RUN brew install $pkg" ;;
    npm:*)  install_cmd="RUN npm install -g ${method#npm:}" ;;
    curl:*) install_cmd="RUN curl -fsSL ${method#curl:} | bash" ;;
  esac

  {
    echo "FROM $BASE_IMAGE"
    echo "USER ubuntu"
    echo "$install_cmd"
  } | docker build --no-cache -t "$image" -f - "$SANDBOX_DIR"
fi

echo "Starting $pkg sandbox..."
echo "Working directory: $(pwd)"
echo ""

# ツール固有の認証情報をマウント
mount_args=()
while IFS= read -r src; do
  src=$(eval echo "$src")
  dst="/home/ubuntu/${src#"$HOME/"}"
  [ -e "$src" ] && mount_args+=(-v "$src:$dst")
done < <(jq -r --arg pkg "$pkg" '.[] | select(.pkg == $pkg) | .mounts[]' "$TOOLS_JSON" 2>/dev/null)

docker run -it --rm \
  -v "$(pwd):$WORKDIR" \
  -v "$HOME/.ssh:/home/ubuntu/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/ubuntu/.gitconfig:ro" \
  "${mount_args[@]}" \
  --workdir "$WORKDIR" \
  --network=host \
  "$image" \
  /bin/bash -c "$yolo_cmd"
