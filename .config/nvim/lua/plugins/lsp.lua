return {
	-- LSP管理
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonUpdate", "MasonLog", "MasonInstall", "MasonUninstall", "MasonUninstallAll" },
		config = true,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			{ "mason-org/mason.nvim" },
			{ "neovim/nvim-lspconfig" },
			{ "saghen/blink.cmp" },
		},
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = (function()
				local path = vim.fn.stdpath("config") .. "/mason.json"
				return vim.fn.json_decode(vim.fn.readfile(path)).servers
			end)(),
			handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({
						-- blink.cmpの機能をLSPに伝える
						capabilities = require("blink.cmp").get_lsp_capabilities(),
					})
				end,
			},
		},
		keys = {
			{ "gd", "<cmd>lua vim.lsp.buf.definition()  <CR>", desc = "Go to definition" },
			{ "gD", "<cmd>lua vim.lsp.buf.declaration() <CR>", desc = "Go to declaration" },
		},
	},
	{
		-- Masonで必要なものを自動的にインストール
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "VeryLazy",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = (function()
					local path = vim.fn.stdpath("config") .. "/mason.json"
					return vim.fn.json_decode(vim.fn.readfile(path)).tools
				end)(),
				auto_update = true,
				run_on_start = true,
			})
		end,
	},
	{
		-- Neovim 設定の Lua ファイルで vim.* の型定義を lua_ls に読み込ませる
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- vim.uv の型定義
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		-- lsp を用いた補完サジェスト機能を提供する
		"saghen/blink.cmp",
		version = "*",
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = {
				-- Enter で補完を確定するキーマッププリセットを使用
				preset = "enter",
				-- Tab キーでも補完を確定する
				["<Tab>"] = {
					-- 選択して確定
					"select_and_accept",
					-- 選択肢がない場合は普通の Tab として機能
					"fallback",
				},
			},
			completion = {
				-- 補完候補メニュー
				menu = {
					-- 自動で補完候補を表示
					auto_show = true,
					-- 見た目を変更
					border = "single",
				},
				-- 補完候補ドキュメント
				documentation = {
					-- 自動で候補のドキュメントを表示
					auto_show = true,
					window = {
						-- 見た目を指定
						border = "single",
					},
				},
				accept = {
					auto_brackets = {
						-- 関数選択時に括弧を自動追加
						enabled = true,
					},
				},
			},
			-- 関数の引数の説明等
			signature = {
				enabled = true,
				window = {
					-- 見た目を指定
					border = "single",
				},
			},
			fuzzy = {
				-- インストール時に lua を使用する
				implementation = "lua",
			},
			sources = {
				-- lazydev を補完候補に追加（require のモジュール名など）
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						-- LSP の候補より上に表示
						score_offset = 100,
					},
				},
			},
		},
	},
	{
		-- 差分を表示しながらコードアクションを実行
		"aznhe21/actions-preview.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
		keys = {
			-- Code Actions 呼び出し
			{
				"<leader>.",
				function()
					require("actions-preview").code_actions()
				end,
				desc = "Code action",
			},
		},
		opts = {},
	},
	{
		"lewis6991/hover.nvim",
		event = "VeryLazy",
		opts = {
			providers = {
				"hover.providers.lsp",
				"hover.providers.diagnostic",
			},
			preview_opts = {
				border = "single",
			},
		},
		keys = {
			-- keymap
			{
				"gh",
				function()
					require("hover").hover()
				end,
				desc = "Hover",
			},
		},
	},
	{
		"antosha417/nvim-lsp-file-operations",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-neo-tree/neo-tree.nvim",
		},
		config = function()
			require("lsp-file-operations").setup()
		end,
	},
}
