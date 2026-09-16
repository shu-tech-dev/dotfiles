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
	{
		-- VS Code のようなマルチカーソル
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		event = "VeryLazy",
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()

			local set = vim.keymap.set
			-- VS Code の Ctrl+Alt+↑/↓ のように、中身に関係なく上下の行の同じ桁へカーソルを追加
			set({ "n", "x" }, "<c-up>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
			set({ "n", "x" }, "<c-down>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })
			-- VS Code の Ctrl+D のように、カーソル下の単語と同じ次の箇所へカーソルを追加
			set({ "n", "x" }, "<c-n>", function() mc.matchAddCursor(1) end, { desc = "Add cursor to next match" })
			-- VS Code の Alt+クリックのように、クリックした位置へカーソルを追加
			set("n", "<c-leftmouse>", mc.handleMouse, { desc = "Add cursor at click" })
			set("n", "<c-leftdrag>", mc.handleMouseDrag, { desc = "Drag cursor selection" })
			set("n", "<c-leftrelease>", mc.handleMouseRelease, { desc = "Release cursor selection" })

			-- 複数カーソルがあるときだけ有効になるキー（通常の <c-c> と共存させるため）
			mc.addKeymapLayer(function(layerSet)
				layerSet("n", "<c-c>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					else
						mc.clearCursors()
					end
				end, { desc = "Clear cursors" })
			end)
		end,
	},
}
