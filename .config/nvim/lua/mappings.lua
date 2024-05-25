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

vim.keymap.set("n", "<leader>tt", function()
  vim.g.transparency_enabled = not vim.g.transparency_enabled
  require("base46").toggle_transparency()
  if vim.g.transparency_enabled then
    vim.notify("Toggled On", vim.log.levels.INFO, { title = "Transparency" })
  else
    vim.notify("Toggled Off", vim.log.levels.INFO, { title = "Transparency" })
  end
end, { desc = "Options | Toggle Transparency", silent = true })

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

for i = 1, 9, 1 do
  vim.keymap.set("n", string.format("<A-%s>", i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end)
end

-- Call "CellularAutomaton make_it_rain" command
map("n", "<leader>mk", "<cmd>CellularAutomaton make_it_rain<CR>", {
  desc = "make it rain",
})
