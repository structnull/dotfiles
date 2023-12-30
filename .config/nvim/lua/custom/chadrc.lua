-- First read our docs (completely) then check the example_config repo

local M = {}

M.plugins = "custom.plugins" -- path for lazy.nvim
M.mappings = require "custom.mappings"

M.ui = {
    theme = "tokyodark",
    statusline = {
        theme = "minimal",
        separator_style = "round",
    },
    transparency = true,
    -- nvdash (dashboard)
    nvdash = {
        load_on_startup = true,
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
    },
}
return M
