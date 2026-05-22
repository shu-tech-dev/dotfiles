return {
	{
		-- 自動でブラケットやクォートを閉じる
		"echasnovski/mini.pairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		build = "cd app && npm install",
		keys = {
			{ "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
		},
	},
}
