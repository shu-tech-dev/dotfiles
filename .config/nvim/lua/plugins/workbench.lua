return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		keys = {
			{ "<c-p>", function() require("telescope.builtin").find_files() end },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					path_display = {
						-- ファイル名を最初に表示
						filename_first = {
							reverse_directiories = false,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
						follow = true,
					},
				},
			})
		end,
	},
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	-- ファイルエクスプローラー
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<c-e>", "<cmd>Neotree focus<CR>" },
		},
		config = function()
			vim.cmd([[highlight NeoTreeDirectoryIcon guifg=#94A3B8]])
			vim.cmd([[highlight NeoTreeFileIcon      guifg=#94A3B8]])
			require("neo-tree").setup({
				filesystem = {
					filtered_items = {
						-- 隠しファイルを表示
						visible = true,
					},
				},
			})
		end,
	},
	-- トグル ターミナル
	{
		"akinsho/toggleterm.nvim",
		keys = { { "<c-t>", "<cmd>ToggleTerm<cr>" } },
		opts = {
			size = 20,
			open_in_dir = "git",
			direction = "float",
			open_mapping = [[<C-t>]],
			insert_mappings = true,
			terminal_mappings = true,
		},
	},
}
