-- Lua バイトコードキャッシュで起動を高速化
vim.loader.enable()

-- 未使用のビルトインプラグインを無効化
local disabled_built_ins = {
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "logipat", "rrhelper", "spellfile_plugin",
  "matchit", "tutor", "rplugin",
}
for _, plugin in ipairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

require("core.base")
require("core.keymaps")

require("config.lazy")
