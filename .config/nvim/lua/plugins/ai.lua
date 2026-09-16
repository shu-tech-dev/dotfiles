return {
    {
        "coder/claudecode.nvim",
        -- TODO 後で設定
        enable = true,
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "folke/snacks.nvim",
        },
        config = function()
            require("claudecode").setup({})
        end,
        keys = {
            -- { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Claude Codeを切り替え" },
            { "<leader>cc", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
            -- { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "セッションを再開" },
            -- { "<leader>as", "<cmd>ClaudeCodeSend<cr>", desc = "選択範囲を送信", mode = "v" },
        },
    }
}
