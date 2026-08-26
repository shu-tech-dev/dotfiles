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
			})
		end,
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview 開く" },
		},
		config = function()
			require("diffview").setup({})
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
		config = function()
			require("gitgraph").setup({})
		end,
	},
}
