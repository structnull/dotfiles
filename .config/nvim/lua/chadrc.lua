-- First read our docs (completely) then check the example_config repo

local M = {}

-- M.plugins = "plugins" -- path for lazy.nvim
-- M.mappings = require "mappings"


M.ui = {
  theme = "tokyodark",
  statusline = {
    theme = "default",
    separator_style = "default",
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

