require "nvchad.mappings"

local map = vim.keymap.set

map("n", "<C-h>", ":TmuxNavigateLeft<CR><ESC>", { desc = "tmux_navigator Window left" })
map("n", "<C-l>", ":TmuxNavigateRight<CR><ESC>", { desc = "tmux_navigator Window right" })
map("n", "<C-j>", ":TmuxNavigateDown<CR><ESC>", { desc = "tmux_navigator Window down" })
map("n", "<C-k>", ":TmuxNavigateUp<CR><ESC>", { desc = "tmux_navigator Window left" })

map("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
end, {
  desc = "Toggle wrap",
})

map(
  "n",
  "<leader>tt",
  ":lua require('base46').toggle_transparency()<CR>",
  { noremap = true, silent = true, desc = "Toggle Background Transparency" }
)

map("n", "<leader>cc", function()
  local file = vim.fn.expand "%:t"
  local fp = vim.fn.expand "%:p:h"
  local ft = vim.bo.ft
  local supported_ft = { "python", "cpp", "c" }

  if not vim.tbl_contains(supported_ft, ft) then
    print "Error: Unsupported file type"
    return
  end

  require("nvchad.term").runner {
    id = "run",
    pos = "sp",
    cmd = function()
      local ft_cmds = {
        python = "python3 " .. file,
        cpp = "clear && g++ -o out " .. file .. " && ./out",
        c = "clear && gcc -o out " .. file .. " && ./out",
      }
      return "cd " .. fp .. " && clear && " .. ft_cmds[ft]
    end,
  }
end, { desc = "Code Runner" })

-- Keyboard users
map("n", "<C-t>", function()
  require("menu").open "default"
end, {})

-- mouse users + nvimtree users!
map("n", "<RightMouse>", function()
  vim.cmd.exec '"normal! \\<RightMouse>"'

  local options = vim.bo.ft == "NvimTree" and "nvimtree" or "default"
  require("menu").open(options, { mouse = true })
end, {})

for i = 1, 9, 1 do
  map("n", string.format("<A-%s>", i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end)
end

for i = 1, 9, 1 do
  map("n", string.format("<D-%s>", i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end)
end

-- Call "CellularAutomaton make_it_rain" command
map("n", "<leader>mk", "<cmd>CellularAutomaton make_it_rain<CR>", {
  desc = "make it rain",
})

-- Global variable to track inline diagnostic virtual text state (off by default)
_G.diagnostics_virtual_text = false

-- Toggle function for inline diagnostics (virtual_text)
local function toggle_diagnostics()
  _G.diagnostics_virtual_text = not _G.diagnostics_virtual_text
  vim.diagnostic.config {
    virtual_text = _G.diagnostics_virtual_text,
    signs = true,
    underline = true,
    update_in_insert = false,
  }
  vim.notify(
    _G.diagnostics_virtual_text and "Inline diagnostics enabled" or "Inline diagnostics disabled",
    vim.log.levels.INFO,
    { title = "Diagnostics" }
  )
end

map(
  { "n" },
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=false hidden=true<CR>",
  { desc = "telescope find all files" }
)

-- manually overriding the mapping passing in the border style
map({ "n" }, "K", function()
  vim.lsp.buf.hover { border = "rounded" }
end, { desc = "LSP show details", silent = true })

-- Map <leader>s to toggle inline diagnostics
map("n", "<leader>s", toggle_diagnostics, { desc = "Toggle inline diagnostics", silent = true })
