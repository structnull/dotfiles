---@type MappingsTable
local M = {}

M.general = {
    n = {
        [";"] = { ":", "enter command mode", opts = { nowait = true } },
        ["<leader>tt"] = {
            function()
                require("base46").toggle_transparency()
            end,
            "toggle transparency",
        },
        ["<leader>tw"] = {
            function()
                if vim.wo.wrap then
                    vim.wo.wrap = false
                else
                    vim.wo.wrap = true
                end
            end,
            "toggle warp",
        },
    },
}

-- more keybinds!

M.nvterm = {
    n = {
        ["<leader>cc"] = {
            function()
                local allowed_filetypes = { "c", "cpp" }
                if not vim.tbl_contains(allowed_filetypes, vim.bo.filetype) then
                    vim.api.nvim_echo({ { "Not a C or C++ file", "WarningMsg" } }, true, {})
                    return
                end
                require("nvterm.terminal").send("clear && g++ -o out " .. vim.fn.expand "%" .. " && ./out", "float")
            end,
            "compile & run a cpp file",
        },
        ["<leader>pc"] = {
            function()
                if vim.bo.filetype ~= "python" then
                    vim.api.nvim_echo({ { "Not a Python file", "WarningMsg" } }, true, {})
                    return
                end
                require("nvterm.terminal").send("clear && python " .. vim.fn.expand "%", "float")
            end,
            "compile & run a python file",
        },
    },
}

return M
