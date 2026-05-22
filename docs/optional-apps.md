# Optional Apps

`install.sh` 実行時に fzf でインタラクティブに選択してインストールできるオプションアプリの定義ファイル。  
nvim・tmux などの必須ツールとは異なり、環境によって不要なアプリ（GUI アプリ等）を管理する。

## ファイル

| ファイル | 役割 |
|---------|------|
| `packages/optional-apps.json` | アプリ定義 |
| `scripts/optional-apps.sh` | インストール・シンボリックリンクのロジック |

## JSON スキーマ

```json
{
  "pkg":         "コマンド名 / brew パッケージ名",
  "name":        "表示名",
  "desc":        "説明",
  "method":      "インストール方法",
  "platforms":   ["対応プラットフォーム"],
  "symlink_src": "dotfiles 内の設定ファイルパス",
  "symlink_dst": "リンク先のパス"
}
```

### method の種類

| method | 例 | 実行されるコマンド |
|--------|----|--------------------|
| `brew` | `"method": "brew"` | `brew install <pkg>` |
| `brew-cask` | `"method": "brew-cask"` | `brew install --cask <pkg>` |

### platforms の種類

| 値 | 環境 |
|----|------|
| `macos` | macOS |
| `linux` | Linux（WSL 以外） |
| `wsl` | WSL |

`platforms` を省略すると全環境で表示される。

## アプリの追加方法

`packages/optional-apps.json` にエントリを追加するだけ。

```json
{
  "pkg":         "new-app",
  "name":        "New App",
  "desc":        "Description of the app",
  "method":      "brew-cask",
  "platforms":   ["macos"],
  "symlink_src": "~/dotfiles/.config/new-app",
  "symlink_dst": "~/.config/new-app"
}
```

設定ファイルが不要なアプリは `symlink_src` / `symlink_dst` を省略できる。
