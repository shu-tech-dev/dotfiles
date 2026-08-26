# Neovim ショートカットキー一覧

※ `<leader>` はデフォルトで `Space` キーに設定されています。

## 基本操作・移動

| モード              | キー                               | アクション                             |
| :------------------ | :--------------------------------- | :------------------------------------- |
| **Insert**          | `jj`                               | Normalモードへ戻る                     |
| **Normal / Visual** | `<s-j>`                            | 10行下へ移動                           |
| **Normal / Visual** | `<s-k>`                            | 10行上へ移動                           |
| **Normal / Visual** | `j`                                | 表示行で下へ移動                       |
| **Normal / Visual** | `k`                                | 表示行で上へ移動                       |
| **Normal / Visual** | `<s-h>`                            | 行頭へ移動                             |
| **Normal / Visual** | `<s-l>`                            | 行末へ移動                             |
| **Normal**          | `<c-h>`, `<c-j>`, `<c-k>`, `<c-l>` | ペイン移動 (左/下/上/右)               |
| **Normal**          | `n` / `<s-n>`                      | 検索結果の次/前へ (画面中央スクロール) |
| **Normal**          | `<esc>`                            | 検索ハイライト消去                     |
| **Terminal**        | `<esc>`                            | TerminalモードからNormalモードへ       |

## 編集・ファイル操作

| モード     | キー          | アクション                    |
| :--------- | :------------ | :---------------------------- |
| **共通**   | `<c-s>`       | 保存                          |
| **共通**   | `<leader>/`   | コメントアウトのトグル        |
| **共通**   | `<c-f>`       | フォーマット実行 (Conform)    |
| **Normal** | `<leader>w`   | 保存                          |
| **Normal** | `<leader>q`   | バッファを閉じる              |
| **Normal** | `<leader>a`   | 全選択                        |
| **Normal** | `<leader>s`   | 水平ペイン分割                |
| **Normal** | `<leader>v`   | 垂直ペイン分割                |
| **Normal** | `<s-d>`, `dd` | yankせずに削除                |
| **Visual** | `d`           | yankせずに削除                |
| **Visual** | `p`           | yankせずにペースト (上書き時) |

## プラグイン・LSP連携

| モード     | キー         | アクション (機能・プラグイン)              |
| :--------- | :----------- | :----------------------------------------- |
| **Normal** | `<c-e>`      | エクスプローラーフォーカス (NeoTree)       |
| **Normal** | `<c-p>`      | ファイル検索 (Telescope)                   |
| **Normal** | `<c-t>`      | ターミナルトグル (ToggleTerm)              |
| **Normal** | `gh`         | ホバー/ドキュメント表示 (Hover/LSP)        |
| **Normal** | `gd`         | 定義へ移動 (LSP)                           |
| **Normal** | `gD`         | 宣言へ移動 (LSP)                           |
| **Normal** | `<leader>.`  | コードアクション (Actions Preview)         |
| **Normal** | `<leader>2`  | リネーム (LSP)                             |
| **Normal** | `<leader>gg` | Gitグラフ表示 (GitGraph)                   |
| **Normal** | `<leader>cc` | Claudeにフォーカス (ClaudeCode)            |
| **Normal** | `<leader>mp` | Markdownプレビュートグル (MarkdownPreview) |
