# dotfiles

## セットアップ

```sh
git clone <this repository> ~/dotfiles
cd ~/dotfiles
./install.sh
```

macOS・Linux に対応。スクリプトが Homebrew・パッケージ・設定ファイルのシンボリックリンクを自動でセットアップします。AIツールとオプションアプリは対話形式で選択できます。完了後はターミナルを再起動してください。

## コマンド

### 開発環境

| コマンド | 説明 |
|---------|------|
| `devup` | tmux開発セッションを起動（nvim + claude + terminal） |
| `devdown` | tmux開発セッションを終了 |
| `ai-sandbox` | AIサンドボックスコンテナを起動 |

### tmux キーバインド（prefix: `Ctrl+t`）

| キー | 説明 |
|------|------|
| `g` | lazygitをフルスクリーンで開く |
| `y` | Claude Codeをポップアップで開く |
| `r` | tmux設定をリロード |
| `e` | 現在のペイン以外をすべて閉じる |
| `Ctrl+Shift+←/→` | ウィンドウの順番を入れ替え |

### devupのレイアウト

```
┌──────────────┬──────────────┐
│              │   claude     │
│    nvim      ├──────────────┤
│              │   terminal   │
└──────────────┴──────────────┘
```
