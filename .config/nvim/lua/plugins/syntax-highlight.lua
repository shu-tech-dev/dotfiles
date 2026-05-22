return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- 使用したい言語を指定
      local languages = {
        "javascript", "jsx", "typescript", "tsx",
        "python"
      }
      require("nvim-treesitter").setup({
        -- Install した言語パーサの配置場所 default のパスを明示的に指定
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })
      -- 指定した言語パーサをインストール
      require("nvim-treesitter").install(languages)
      vim.api.nvim_create_autocmd({ "FileType" }, {
        -- 使用したい言語のファイルを開いたときのみ実行
        pattern = languages,
        callback = function()
          -- Syntax highlighting を有効化（パーサー未インストール時はスキップ）
          if pcall(vim.treesitter.start) then
            -- 折りたたみを有効化
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
        end,
      })
    end
  },
}
