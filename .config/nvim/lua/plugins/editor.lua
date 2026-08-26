return {
	{
		-- 自動でブラケットやクォートを閉じる
		"echasnovski/mini.pairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		-- Neovim内でmarkdownをレンダリング
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
}
