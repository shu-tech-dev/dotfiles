-- upgrade.sh --nvim から nvim --headless で実行される。
-- ユーザー設定を読み込んだ nvim の中で、プラグイン・パーサー・Mason パッケージを順に最新にする。

local function log(msg)
  io.stdout:write(msg, "\n")
end

-- lazy.nvim: install / clean / update をまとめて同期実行（lazy-lock.json が更新される）
log("  → lazy.nvim: sync plugins")
require("lazy").sync({ wait = true, show = false })

-- nvim-treesitter: インストール済みパーサーを更新
log("  → nvim-treesitter: update parsers")
require("nvim-treesitter").update():wait(300000)

-- Mason: インストール済みの全パッケージ（LSP サーバー・フォーマッター）を最新バージョンにする
log("  → mason: update installed packages")
local registry = require("mason-registry")
local refreshed = false
registry.refresh(function()
  refreshed = true
end)
vim.wait(60000, function()
  return refreshed
end, 200)

local pending = 0
for _, pkg in ipairs(registry.get_installed_packages()) do
  local installed, latest = pkg:get_installed_version(), pkg:get_latest_version()
  -- mason-tool-installer の auto_update が起動時に同じパッケージを更新中のことがあるので、その場合は任せる
  if installed ~= latest and not pkg:is_installing() then
    log(("    %s %s -> %s"):format(pkg.name, tostring(installed), latest))
    pending = pending + 1
    pkg:install({ version = latest }, function(ok, err)
      if not ok then
        log(("    ! %s: %s"):format(pkg.name, tostring(err)))
      end
      pending = pending - 1
    end)
  end
end
vim.wait(600000, function()
  return pending == 0
end, 200)

vim.cmd("qa!")
