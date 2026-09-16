return {
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000, -- Ensure it loads first
		config = function()
			require("onedarkpro").setup({
				options = {
					transparency = true,
				},
				highlights = {
					-- bufferline のアクティブタブの下線色に使われるので VS Code の青にする
					TabLineSel = { bg = "#0078d4" },
					-- gitgraph のデフォルト（gruvbox 系）の色を onedark のパレットに合わせる
					GitGraphBranch1 = { fg = "${blue}" },
					GitGraphBranch2 = { fg = "${purple}" },
					GitGraphBranch3 = { fg = "${yellow}" },
					GitGraphBranch4 = { fg = "${green}" },
					GitGraphBranch5 = { fg = "${red}" },
					GitGraphHash = { fg = "${comment}" },
					GitGraphTimestamp = { fg = "${comment}" },
					GitGraphAuthor = { fg = "${cyan}" },
					GitGraphBranchName = { fg = "${red}", bold = true },
					GitGraphBranchTag = { fg = "${yellow}" },
					GitGraphBranchMsg = { fg = "${fg}" },
					-- diffview で VS Code のように左（変更前）を赤・右（変更後）を緑にする色（git.lua の hooks で使用）
					DiffviewVscodeDelete = { bg = "#4a2f35" },
					DiffviewVscodeDeleteText = { bg = "#7a3a44" },
					DiffviewVscodeAdd = { bg = "#2f4a36" },
					DiffviewVscodeAddText = { bg = "#3d6b47" },
				},
			})
			vim.cmd("colorscheme onedark")
		end,
	},
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		config = function()
			-- Colors
			vim.cmd([[highlight DashboardHeader       guifg=#94A3B8]])
			vim.cmd([[highlight DashboardProjectTitle guifg=#94A3B8]])
			vim.cmd([[highlight DashboardProjectIcon  guifg=#475569]])
			vim.cmd([[highlight DashboardFiles        guifg=#9E9E9E]]) -- ファイル一覧
			vim.cmd([[highlight DashboardFooter       guifg=#607d8b]]) -- フッター (outerbg)

			-- プロジェクトを開いてディレクトリ移動するカスタムコマンド
			vim.api.nvim_create_user_command("OpenProject", function(opts)
				local path = opts.args
				vim.cmd("cd " .. path)
				require("telescope.builtin").find_files({ cwd = path })
			end, { nargs = 1 })

			require("dashboard").setup({
				theme = "hyper",
				config = {
					header = {
						[[                                                                       ]],
						[[                                                                     ]],
						[[       ████ ██████           █████      ██                     ]],
						[[      ███████████             █████                             ]],
						[[      █████████ ███████████████████ ███   ███████████   ]],
						[[     █████████  ███    █████████████ █████ ██████████████   ]],
						[[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
						[[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
						[[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
						[[                                                                       ]],
					},
					-- 1. 不要なセクションを無効化・非表示にする
					week_header = { enable = false }, -- 週間ヘッダーを無効化 [1]
					shortcut = {}, -- ショートカットメニューを空にして非表示 [1]
					mru = { enable = false }, -- 最近使ったファイル (MRU) を無効化 [1]
					footer = {}, -- フッターを削除 [1]

					-- 2. プロジェクト一覧 (Recent Projects) のみを有効化
					project = {
						enable = true,
						limit = 10, -- 表示するプロジェクト数
						icon = " ", -- アイコン設定 [1]
						label = "Recent Projects", -- ラベル名
						action = "OpenProject ", -- プロジェクト選択時にディレクトリ移動してファイル検索
					},
				},
			})
		end,
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = {
				theme = function()
					local colors = {
						darkgray = "#212121",
						gray = "#9E9E9E",
						innerbg = nil,
						outerbg = "#607d8b",
						normal = "#03A9F4",
						insert = "#b2ff59",
						visual = "#b388ff",
						replace = "#FF9800",
						command = "#795548",
					}
					return {
						inactive = {
							a = { fg = colors.gray, bg = colors.outerbg, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						visual = {
							a = { fg = colors.darkgray, bg = colors.visual, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						replace = {
							a = { fg = colors.darkgray, bg = colors.replace, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						normal = {
							a = { fg = colors.darkgray, bg = colors.normal, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						insert = {
							a = { fg = colors.darkgray, bg = colors.insert, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						command = {
							a = { fg = colors.darkgray, bg = colors.command, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
						terminal = {
							a = { fg = colors.darkgray, bg = colors.command, gui = "bold" },
							b = { fg = colors.darkgray, bg = colors.outerbg },
							c = { fg = colors.gray, bg = colors.innerbg },
						},
					}
				end,
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = {
					{
						"filename",
						file_status = true, -- displays file status (readonly status, modified status)
						path = 0, -- 0 = just filename, 1 = relative path, 2 = absolute path
					},
				},
				lualine_x = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = {
							error = " ",
							warn = " ",
							info = " ",
							hint = " ",
						},
					},
					"encoding",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = {},
		},
	},
}
