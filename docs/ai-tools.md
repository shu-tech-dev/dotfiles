# AI Tools

`install.sh` 実行時に fzf でインタラクティブに選択してインストールできる AI ツールの定義ファイル。

## ファイル

| ファイル                 | 役割                 |
| ------------------------ | -------------------- |
| `packages/ai-tools.json` | ツール定義           |
| `scripts/ai-tools.sh`    | インストールロジック |

## JSON スキーマ

```json
{
  "pkg": "コマンド名 / brew パッケージ名",
  "name": "表示名",
  "desc": "説明",
  "method": "インストール方法"
}
```

### method の種類

| method          | 例                              | 実行されるコマンド         |
| --------------- | ------------------------------- | -------------------------- |
| `brew`          | `"method": "brew"`              | `brew install <pkg>`       |
| `npm:<package>` | `"method": "npm:@openai/codex"` | `npm install -g <package>` |
| `curl:<url>`    | `"method": "curl:https://..."`  | `curl -fsSL <url> \| bash` |

## ツールの追加方法

`packages/ai-tools.json` にエントリを追加するだけ。

```json
{
  "pkg": "new-tool",
  "name": "New Tool",
  "desc": "Description of the tool",
  "method": "brew"
}
```
