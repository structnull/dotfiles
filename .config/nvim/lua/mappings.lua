require "nvchad.mappings"

vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR><ESC>", { desc = "tmux_navigator Window left" })
vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR><ESC>", { desc = "tmux_navigator Window right" })
vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR><ESC>", { desc = "tmux_navigator Window down" })
vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR><ESC>", { desc = "tmux_navigator Window left" })

vim.keymap.set("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
end, {
  desc = "Toggle wrap",
})

-- Compile and run C/C++ file
vim.keymap.set("n", "<leader>cc", function()
  local allowed_filetypes = { "c", "cpp" }
  if not vim.tbl_contains(allowed_filetypes, vim.bo.filetype) then
    vim.api.nvim_echo({ { "Not a C or C++ file", "WarningMsg" } }, true, {})
    return
  end
  require("nvterm.terminal").send("clear && g++ -o out " .. vim.fn.expand "%" .. " && ./out", "float")
end, {
  desc = "Compile & run a C/C++ file",
})

-- Call "CellularAutomaton make_it_rain" command
vim.keymap.set("n", "<leader>mk", "<cmd>CellularAutomaton make_it_rain<CR>", {
  desc = "make it rain",
})

-- Compile and run Python file
vim.keymap.set("n", "<leader>pc", function()
  if vim.bo.filetype ~= "python" then
    vim.api.nvim_echo({ { "Not a Python file", "WarningMsg" } }, true, {})
    return
  end
  require("nvterm.terminal").send("clear && python " .. vim.fn.expand "%", "float")
end, {
  desc = "Compile & run a Python file",
})
