return {
  {
    -- フォーマッタ
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<c-f>",
        function()
          require("conform").format({
            async = true,
            lsp_fallback = true,
            timeout_ms = 500,
          })
        end,
        mode = { "n", "v", "i" },
      },
    },
    opts = function()
      -- プロジェクトに biome.json があれば biome、なければ prettier
      local function js_formatter(bufnr)
        local found = vim.fs.find(
          { "biome.json", "biome.jsonc" },
          { upward = true, path = vim.api.nvim_buf_get_name(bufnr) }
        )[1]
        return found and { "biome" } or { "prettier" }
      end

      return {
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "ruff_format" },
          javascript = js_formatter,
          typescript = js_formatter,
          javascriptreact = js_formatter,
          typescriptreact = js_formatter,
          json = js_formatter,
          jsonc = js_formatter,
          markdown = { "prettier" },
        },
      }
    end,
  }
}
