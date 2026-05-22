# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## 概要

これはLuaで書かれたNeovim設定リポジトリで、lazy.nvimプラグインマネージャーを使用しています。MacOSに特化した設定で、LSP、フォーマッティング、UIカスタマイズ、各種編集機能の強化が含まれています。

## 必要要件

- MacOS
- NeoVim
- Homebrew
- ripgrep: `brew install ripgrep`
- fd: `brew install fd`
- tree-sitter-cli: `brew install tree-sitter-cli`

## アーキテクチャ

### エントリーポイントとプラグイン読み込み

- `init.lua` - コア設定とlazy.nvimを読み込むメインエントリーポイント
- `lua/config/lazy.lua` - lazy.nvimプラグインマネージャーを起動し、`lua/plugins/`配下の全プラグイン設定を自動読み込み
- プラグイン管理はlazy.nvimを使用し、自動インストールと更新を行う

### コア設定

`lua/core/`に配置:

- `base.lua` - エディタ設定（エンコーディング、UI、インデント、検索、クリップボード、折りたたみ）
  - UTF-8エンコーディング、expandtabで2スペースインデント
  - グローバルステータスライン（laststatus=3）、サイン列は常に表示
  - スマート検索（ignorecase + smartcase）
  - スワップファイルなし、システムクリップボード統合
- `keymaps.lua` - すべてのカスタムキーバインド
  - Leaderキー: Space
  - `jj` でインサートモードを抜ける
  - 移動: `Shift+J/K` (10行)、`Shift+H/L` (行頭/行末)
  - 保存: `Ctrl+S` または `<leader>w`
  - LSP: `gh` (ホバー)、`gd` (定義)、`gD` (宣言)、`<leader>.` (コードアクション)、`<leader>2` (リネーム)
  - ワークベンチ: `Ctrl+P` (ファイル検索)、`Ctrl+E` (ファイルツリーフォーカス)
  - フォーマット: `Ctrl+F`
  - ウィンドウナビゲーション: `<leader>h/j/k/l`
  - コメント: `<leader>/`
  - yankしない削除: `dd`、`d` (ビジュアル)、`Shift+D`

### プラグイン構成

`lua/plugins/`で機能ごとに整理:

- `lsp.lua` - 言語サーバー設定
  - Mason: LSP/ツール管理
  - blink.cmp: 補完（Tab/Enterで確定）
  - actions-preview: 差分プレビュー付きコードアクション
  - hover.nvim: ホバードキュメント
  - 自動インストール: stylua、prettier、ruff

- `format.lua` - コードフォーマット
  - conform.nvim: `Ctrl+F`キーバインド
  - フォーマッター: stylua (Lua)、prettier (JS/TS/JSON/MD)、ruff_format (Python)

- `ui.lua` - UIカスタマイズ
  - onedarkpro: カラースキーム
  - dashboard-nvim: 最近のプロジェクト表示
  - lualine.nvim: カスタムテーマのステータスライン

- `workbench.lua` - ナビゲーションとファイル管理
  - telescope.nvim: ファジー検索（`Ctrl+P`）
  - bufferline.nvim: バッファタブ
  - neo-tree.nvim: ファイルエクスプローラー（`Ctrl+E`）

- `editor.lua` - 編集機能の強化
  - mini.pairs: ブラケット/クォートの自動閉じ
  - mini.move: 行移動（`Ctrl+J/K`）

- `syntax-highlight.lua` - Treesitter設定
  - 対応言語: JavaScript、JSX、TypeScript、TSX、Python
  - シンタックスハイライト、折りたたみ、インデントを有効化

- `git.lua` - Git統合
  - gitsigns.nvim: 現在行のblameを表示（300ms遅延）

- `ai.lua` - AI統合（現在無効）
  - claudecode.nvimプラグイン設定済みだが未有効化

## プラグインヘルスチェック

プラグインのインストールと設定を確認:

```vim
:checkhealth <Plugin Name>
```

## 主要な設定パターン

### プラグイン仕様の構造

プラグインはlazy.nvimの宣言的な仕様フォーマットを使用:
- `event` - 特定のイベントで読み込み（例: `BufReadPre`, `VimEnter`）
- `keys` - キーマップ使用時に読み込み（遅延読み込みキーバインド）
- `cmd` - コマンド実行時に読み込み
- `dependencies` - プラグイン依存関係
- `opts` - プラグインオプション（`.setup()`に渡される）
- `config` - カスタムセットアップ関数

### LSPセットアップフロー

1. MasonがLSPサーバーとツールをインストール
2. mason-lspconfigがblink.cmpの機能を含めてサーバーを設定
3. mason-tool-installerがフォーマッター/リンターを自動インストール
4. LSPキーバインドは`keymaps.lua`とプラグイン固有の`keys`テーブルの両方で定義

### フォーマットワークフロー

- Conform.nvimがすべてのフォーマットを処理
- 言語固有のフォーマッターは`formatters_by_ft`で定義
- フォーマッターが設定されていない場合はLSPフォーマットにフォールバック
- ノーマル/ビジュアル/インサートモードで`Ctrl+F`で起動

## 開発メモ

- すべての日本語コメントは重要な設定の意思決定を示すため保持
- Leaderキー（`<leader>`）はSpace - キーマップ全体で参照される
- `keymaps.lua`内の多くのコメントアウトされたキーバインドは過去の設定履歴を示す
- Treesitter言語パーサーは手動指定（自動インストールではない）
- パフォーマンスのためプラグインの遅延読み込みを広範囲に使用
