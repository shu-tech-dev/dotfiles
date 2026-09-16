return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		keys = {
			{ "<c-p>", function() require("telescope.builtin").find_files() end },
			-- VS Code の Ctrl+Shift+F のようにプロジェクト全体を全文検索（ターミナルでは Ctrl+Shift+F を区別できないため leader）
			{ "<leader>f", function() require("telescope.builtin").live_grep() end, desc = "Search in files" },
			-- VS Code風のドロップダウンUIでコマンドパレットを開く（幅と高さを少し大きめに設定）
			{ "<leader>p", function() require("telescope.builtin").commands(require("telescope.themes").get_dropdown({ layout_config = { width = 0.6, height = 0.6 } })) end, desc = "Command Palette" },
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
						-- live_grep と同じ rg に統一する（.git などの除外は ~/.config/ripgrep/config で管理）
						find_command = { "rg", "--files", "--color", "never" },
						hidden = true,
						follow = true,
					},
					live_grep = {
						-- find_files と同様に dotfile も検索対象にする
						additional_args = { "--hidden" },
					},
				},
			})
		end,
	},
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		-- style_preset で require("bufferline") を参照するため関数で渡す
		opts = function()
			return {
				options = {
					-- VS Code に合わせてアクティブなタブを斜体にしない
					style_preset = require("bufferline").style_preset.no_italic,
					-- VS Code のようにエクスプローラーの右側からタブを並べる
					offsets = {
						{ filetype = "neo-tree", text = "EXPLORER", text_align = "left", separator = true },
					},
					-- VS Code のようにタブに診断（エラー・警告）を表示
					diagnostics = "nvim_lsp",
					-- アクティブなタブの下に線を引く（線の色は TabLineSel の背景色。ui.lua で設定）
					indicator = { style = "underline" },
					-- 閉じるボタンは各タブ・右端ともに常に非表示
					show_buffer_close_icons = false,
					show_close_icon = false,
				},
			}
		end,
	},
	{
		"folke/snacks.nvim",
		keys = {
			-- VS Code のタブを閉じる操作のように、ウィンドウレイアウトを崩さずにバッファだけ閉じる
			{ "<leader>q", function() require("snacks").bufdelete() end, desc = "Close buffer" },
		},
	},
	-- キー入力の途中で、続けて押せるキーの候補を表示
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			spec = {
				{ "<leader>g", group = "Git" },
				{ "<leader>c", group = "Claude" },
			},
		},
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
						-- dotfile はフィルタ対象外にして通常と同じ色で表示（gitignore 対象は引き続きグレー）
						hide_dotfiles = false,
						-- visible = true でも常に非表示
						never_show = { ".git" },
					},
				},
				default_component_configs = {
					-- VS Code のエクスプローラーに合わせて git 状態を文字で表示
					git_status = {
						symbols = {
							added = "A",
							deleted = "D",
							modified = "M",
							renamed = "R",
							untracked = "U",
							conflict = "!",
							-- VS Code では表示しない
							ignored = "",
							unstaged = "",
							staged = "",
						},
					},
					-- VS Code に合わせてエラー（赤）と警告（黄）だけ表示。件数は設定では出せないので ● で代用
					diagnostics = {
						symbols = {
							error = "●",
							warn = "●",
							info = "",
							hint = "",
						},
					},
				},
			})
		end,
	},
	-- トグル ターミナル
	{
		"akinsho/toggleterm.nvim",
		keys = { { "<c-\\>", "<cmd>ToggleTerm<cr>" } },
		opts = {
			size = 50,
			open_in_dir = "git",
			direction = "vertical",
			open_mapping = [[<C-\>]],
			insert_mappings = true,
			terminal_mappings = true,
		},
	},
}
