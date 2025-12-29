-- First read our docs (completely) then check the example_config repo

local M = {}

M.base46 = {
     theme = "tokyodark",
     hl_add = {},
     hl_override = {},
     integrations = {},
     changed_themes = {},
     transparency = true,
}


-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
--}


M.nvdash = {
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
}

return M


