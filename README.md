# dotfiles

## セットアップ

```sh
git clone <this repository> ~/dotfiles
cd ~/dotfiles
./install.sh
```

macOS・Linux に対応。スクリプトが Homebrew・パッケージ・設定ファイルのシンボリックリンクを自動でセットアップします。AIツールとオプションアプリは対話形式で選択できます。完了後はターミナルを再起動してください。

導入したものは `~/.local/state/dotfiles/manifest.tsv` に記録され、既存の設定ファイルを置き換える場合は `~/.local/state/dotfiles/backups/` に退避されます。

## アンインストール

```sh
./uninstall.sh --dry-run   # 何が消えるかだけ表示
./uninstall.sh             # 対話でカテゴリを選択
```

**install.sh が実際に入れたものだけ**を削除します。記録に無いもの（＝元から入っていたもの）には触りません。実ファイル・実ディレクトリは削除対象外で、`~/dotfiles` を指すシンボリックリンクのみを外し、退避してあった元ファイルを書き戻します。

| カテゴリ | 対象 |
|---------|------|
| `--links` | シンボリックリンク、rcファイルへの追記、TPM、バックアップの復元 |
| `--packages` | dotfiles が入れた brew formula / cask、グローバル npm パッケージ、dotfiles が配置した実行ファイル |
| `--node` | dotfiles が入れた nvm・Node.js |
| `--system` | apt パッケージ、Homebrew 本体、ログインシェルの復帰 |
| `--all` | 上記すべて |

オプション: `-n/--dry-run`、`-y/--yes`、`-h/--help`

`--system` は毎回個別に確認を取ります。ログインシェルは記録された元のシェルにのみ戻し、記録が無ければ変更しません。brew は `--ignore-dependencies` を付けないため、他が依存している formula は brew 側が拒否して残ります。

install.sh 以前に導入したなど記録が無い場合は fallback モードになり、候補を提示して選ばせる方式に切り替わります（既定では何も選択されていません）。このモードでは `--system` は動作しません。

## コマンド

### 開発環境

| コマンド | 説明 |
|---------|------|
| `devup` | tmux開発セッションを起動（nvim + claude + terminal） |
| `devdown` | tmux開発セッションを終了 |

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
