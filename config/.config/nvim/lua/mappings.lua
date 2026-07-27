require "nvchad.mappings"

local map = vim.keymap.set

-- Window navigation (tmux-navigator)
map("n", "<C-h>", function()
  vim.cmd.TmuxNavigateLeft()
end, { desc = "tmux_navigator Window left" })

map("n", "<C-l>", function()
  vim.cmd.TmuxNavigateRight()
end, { desc = "tmux_navigator Window right" })

map("n", "<C-j>", function()
  vim.cmd.TmuxNavigateDown()
end, { desc = "tmux_navigator Window down" })

map("n", "<C-k>", function()
  vim.cmd.TmuxNavigateUp()
end, { desc = "tmux_navigator Window up" })

-- Editor toggles
map("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })

map("n", "<leader>tt", function()
  require("base46").toggle_transparency()
end, { noremap = true, silent = true, desc = "Toggle Background Transparency" })

map("n", "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "code action" })

-- Code runner / Flutter commands
map("n", "<leader>cc", function()
  local file = vim.fn.expand "%:t"
  local fp = vim.fn.expand "%:p:h"
  local ft = vim.bo.filetype
  local supported_ft = { "python", "cpp", "c" }

  local is_flutter_project = vim.fn.filereadable "pubspec.yaml" == 1
    and vim.fn.match(vim.fn.readfile "pubspec.yaml", "flutter") >= 0

  if is_flutter_project then
    require("telescope").extensions.flutter.commands()
    return
  end

  if not vim.tbl_contains(supported_ft, ft) then
    vim.notify("Unsupported file type: " .. ft, vim.log.levels.ERROR)
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
end, { desc = "Code Runner or Flutter Commands" })

-- Mouse / nvimtree context menu
map("n", "<RightMouse>", function()
  vim.cmd.exec '"normal! \\<RightMouse>"'
  local options = vim.bo.ft == "NvimTree" and "nvimtree" or "default"
  require("menu").open(options, { mouse = true })
end, {})

-- Buffer switching (Alt/Cmd + number)
for i = 1, 9 do
  local goto_buf = function()
    local buf = vim.t.bufs[i]
    if buf then
      vim.api.nvim_set_current_buf(buf)
    end
  end
  map("n", string.format("<A-%s>", i), goto_buf, { desc = "Go to buffer " .. i })
  map("n", string.format("<D-%s>", i), goto_buf, { desc = "Go to buffer " .. i })
end

-- Fun / misc
map("n", "<leader>mk", function()
  vim.cmd.CellularAutomaton "make_it_rain"
end, { desc = "make it rain" })

-- Diagnostics toggle
_G.diagnostics_virtual_text = false

map("n", "<leader>s", function()
  _G.diagnostics_virtual_text = not _G.diagnostics_virtual_text
  vim.diagnostic.config {
    virtual_text = _G.diagnostics_virtual_text,
    signs = true,
    underline = true,
    update_in_insert = false,
  }
end, { desc = "Toggle inline diagnostics", silent = true })

-- Telescope
map("n", "<leader>fa", function()
  require("telescope.builtin").find_files { no_ignore = false, hidden = true }
end, { desc = "telescope find all files" })

-- LSP
map("n", "K", function()
  vim.lsp.buf.hover { border = "rounded" }
end, { desc = "LSP show details", silent = true })
