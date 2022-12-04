-- First read our docs (completely) then check the example_config repo

local M = {}

M.ui = {
    theme = "tokyodark",
    transparency = true,
}

M.plugins = require "custom.plugins"

return M
