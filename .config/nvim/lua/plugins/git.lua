return {
	{
		-- カーソルのある行のGitの情報をゴーストテキストとして表示
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				-- デフォルトでLine Blameを表示する
				current_line_blame = true,
				current_line_blame_opts = {
					-- 表示までの遅延時間（ミリ秒）
					delay = 300,
				},
				-- 変更行の線を太くする（デフォルトの ┃ は細くて見づらいため、左半分のブロック文字にする）
				signs = {
					add = { text = "▌" },
					change = { text = "▌" },
					untracked = { text = "▌" },
				},
				signs_staged = {
					add = { text = "▌" },
					change = { text = "▌" },
				},
			})
		end,
	},
	{
		-- VS Code の Source Control のように、変更一覧からステージ・コミットする
		"NeogitOrg/neogit",
		cmd = "Neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
		},
		keys = {
			{ "<leader>gs", "<cmd>Neogit<cr>", desc = "Open Neogit" },
		},
		opts = {
			-- 差分表示に diffview を使う（diffview 側の色設定がそのまま効く）
			integrations = { diffview = true },
		},
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
		},
		config = function()
			require("diffview").setup({
				-- 左側（変更前）の行を赤、右側（変更後）を緑で表示し、空白の埋め草を目立たなくして VS Code の diff ビューに近づける
				enhanced_diff_hl = true,
				hooks = {
					-- Vim の diff は書き換えた行を左右とも DiffChange（灰色）で表示するので、
					-- VS Code のように左（変更前）は赤・右（変更後）は緑になるよう、ウィンドウごとに色を差し替える
					diff_buf_win_enter = function(_, winid, ctx)
						if ctx.layout_name ~= "diff2_horizontal" then
							return
						end
						if ctx.symbol == "a" then
							vim.wo[winid].winhl =
								"DiffAdd:DiffviewVscodeDelete,DiffDelete:DiffviewDiffDeleteDim,DiffChange:DiffviewVscodeDelete,DiffText:DiffviewVscodeDeleteText"
						else
							vim.wo[winid].winhl =
								"DiffAdd:DiffviewVscodeAdd,DiffDelete:DiffviewDiffDeleteDim,DiffChange:DiffviewVscodeAdd,DiffText:DiffviewVscodeAddText"
						end
					end,
				},
			})
		end,
	},
	{
		"isakbm/gitgraph.nvim",
		dependencies = { "sindrets/diffview.nvim" },
		keys = {
			{
				"<leader>gg",
				function()
					require("gitgraph").draw({}, { all = true })
				end,
				desc = "GitGraph",
			},
		},
		opts = {
			-- kitty 専用のグリフは WSL では表示できないので、一般的な Unicode 記号にする
			symbols = { merge_commit = "◉", commit = "●", merge_commit_end = "◉", commit_end = "●" },
			format = {
				timestamp = "%Y-%m-%d %H:%M",
				fields = { "hash", "timestamp", "author", "branch_name", "tag" },
			},
			hooks = {
				-- Enter でカーソル下のコミットの差分を diffview で開く
				on_select_commit = function(commit)
					vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
				end,
				-- ビジュアルモードで範囲選択して Enter で、範囲全体の差分を開く
				on_select_range_commit = function(from, to)
					vim.cmd("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
				end,
			},
		},
	},
}
