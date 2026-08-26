local map = vim.keymap.set
local opts = { noremap = true, silent = true }

------------------------------------------------------------------------
-- Base Settings
------------------------------------------------------------------------
-- Leader Key ----------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

------------------------------------------------------------------------
-- Insert Mode
------------------------------------------------------------------------
map({ "i" }, "jj", "<esc>", { desc = "Insert を抜ける" })

------------------------------------------------------------------------
-- Normal & Visual Mode
------------------------------------------------------------------------
-- Move ----------------------------------------------------------------
map({ "n", "v" }, "<s-j>", "10j") -- で10行上に移動する
map({ "n", "v" }, "<s-k>", "10k") -- で10行下に移動する
map({ "n", "v" }, "j", "gj") -- 表示行で下へ移動
map({ "n", "v" }, "k", "gk") -- 表示行で上へ移動
map({ "n", "v" }, "<s-h>", "^") -- 行の最初へ移動
map({ "n", "v" }, "<s-l>", "$") -- 行の最後へ移動
-- Save ----------------------------------------------------------------
map({ "n", "v" }, "<c-s>", ":w<cr>") -- 変更を保存

------------------------------------------------------------------------
-- Normal Mode
------------------------------------------------------------------------
-- 削除時に yank されないようにする
map({ "n" }, "<s-d>", '"_D')
-- 削除時に yank されないようにする
map({ "n" }, "dd", '"_dd')
-- 次の検索結果に移動するとき検索結果が中央になるようにスクロール位置を移動する
map({ "n" }, "n", "nzz")
-- 前の検索結果に移動するとき検索結果が中央になるようにスクロール位置を移動する
map({ "n" }, "<s-n>", "Nzz")
-- 検索結果のハイライトを消す
map({ "n" }, "<esc>", ":nohl<cr>")
-- 下のペインに移動
map({ "n" }, "<c-j>", "<c-w>j")
-- 左のペインに移動
map({ "n" }, "<c-h>", "<c-w>h")
-- 上のペインに移動
map({ "n" }, "<c-k>", "<c-w>k")
-- 右のペインに移動
map({ "n" }, "<c-l>", "<c-w>l")
-- 全選択
map({ "n" }, "<leader>a", "ggVG")
-- バッファを閉じる
map({ "n" }, "<leader>q", ":q<cr>")
-- Quick Fix
map({ "n" }, "<leader>.", "<cmd>lua vim.lsp.buf.code_action()<CR>")
-- Rename
map({ "n" }, "<leader>2", "<cmd>lua vim.lsp.buf.rename()<CR>")
-- ペイン分割
map({ "n" }, "<leader>s", ":split<cr>", opts)
map({ "n" }, "<leader>v", ":vsplit<cr>", opts)
-- コメントアウト
map({ "n" }, "<leader>/", "gcc", { remap = true })
map({ "n" }, "<leader>w", ":w<cr>")
map({ "t" }, "<Esc>", [[<C-\><C-n>]], { noremap = true })
-- 3ペインレイアウト再構築（Neo-tree + ターミナル）
map({ "n" }, "<leader>W", function()
  vim.cmd("Neotree show")
  vim.cmd("ToggleTerm")
end, { desc = "レイアウト再構築" })


--map({ "n" } , "gh", ':lua require("noice.lsp").hover()<cr>', opts)
-- map('n', 'gh', ':Lspsaga hover_doc<cr>', opts)
-- map('n', 'gh', ':lua Show_hover_and_diagnostics()<cr>', opts)
--map({ "n" } , "gn", ":lua vim.diagnostic.goto_next()<cr>", opts)
--map({ "n" } , "gp", ":lua vim.diagnostic.goto_prev()<cr>", opts)
--map({ "n" } , "<c-e>", ':lua require("nvim-tree.api").tree.focus()<cr>', opts)
--map({ "n" } , "<tab>", ":BufferLineCycleNext<cr>", opts)
--map({ "n" } , "<s-tab>", ":BufferLineCyclePrev<cr>", opts)
-- map({ "n" }, "<leader>]", ":lua vim.lsp.buf.definition()<cr>", opts)
-- map({ "n" }, "<leader>[", ":lua vim.lsp.buf.type_definition()<cr>", opts)
-- map({ "n" }, "<leader>2", ":lua vim.lsp.buf.rename()<cr>", opts)
-- map('n', '<leader>.', ':lua vim.lsp.buf.code_action()<cr>', opts)
-- map({ "n" }, "<leader>n", ":tabnew<cr>", opts)
-- map({ "n" }, "<leader>\\", ':lua require("telescope.builtin").lsp_references()<cr>', opts)
-- map({ "n" }, "<leader>gd", ":DiffViewFile", opts) -- 右のペインに移動
-- map({ "n" }, "<leader>gh", "vim.diagnostic.open_float()<cr>", opts)
-- map({ "n" }, "<c-a>p", ':lua require("telescope").extensions.project.project()<cr>', opts)
-- map({ "n" }, "<c-a>b", ":Telescope buffers<cr>", opts)     -- 右のペインに移動
-- map({ "n" }, "<c-a>c", ":Telescope git_commits<cr>", opts) -- 右のペインに移動
-- map({ "n" }, "<c-a>s", ":Telescope git_status<cr>", opts)  -- 右のペインに移動
-- map({ "n" }, "<c-a>g", ":Telescope live_grep<cr>", opts)   -- 右のペインに移動

------------------------------------------------------------------------
-- Visual Mode
------------------------------------------------------------------------
-- Copy & Paste --------------------------------------------------------
map({ "v" }, "p", '"_dp') -- 上書き Paste 時に上書き元を yank しないようにする
-- Edit ----------------------------------------------------------------
map({ "v" }, "<leader>/", "gc") -- コメントアウト
-- Delete --------------------------------------------------------------
map({ "v" }, "d", '"_d') -- 削除時に yank しないようにする
-- コメントアウト
map({ "v" }, "<leader>/", "gc", { remap = true })
