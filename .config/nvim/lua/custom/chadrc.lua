-- First read our docs (completely) then check the example_config repo

local M = {}

M.plugins = "custom.plugins" -- path for lazy.nvim
M.mappings = require "custom.mappings"

M.ui = {
    theme = "onedark",
    statusline = {
        theme = "minimal",
        separator_style = "round",
    },
    transparency = true,
    -- nvdash (dashboard)
    nvdash = {
        load_on_startup = false,
        header = {
            "  ██████████▀▀▀▀▀▀▀▀▀▀▀▀▀██████████  ",
            "  █████▀▀░░░░░░░░░░░░░░░░░░░▀▀█████  ",
            "  ███▀░░░░░░░░░░░░░░░░░░░░░░░░░▀███  ",
            "  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██  ",
            "  █░░░░░░▄▄▄▄▄▄░░░░░░░░▄▄▄▄▄▄░░░░░█  ",
            "  █░░░▄██▀░░░▀██░░░░░░██▀░░░▀██▄░░█  ",
            "  █░░░██▄░░▀░░▄█░░░░░░█▄░░▀░░▄██░░█  ",
            "  ██░░░▀▀█▄▄▄██░░░██░░░██▄▄▄█▀▀░░██  ",
            "  ███░░░░░░▄▄▀░░░████░░░▀▄▄░░░░░███  ",
            "  ██░░░░░█▄░░░░░░▀▀▀▀░░░░░░░█▄░░░██  ",
            "  ██░░░▀▀█░█▀▄▄▄▄▄▄▄▄▄▄▄▄▄▀██▀▀░░██  ",
            "  ███░░░░░▀█▄░░█░░█░░░█░░█▄▀░░░░███  ",
            "  ████▄░░░░░░▀▀█▄▄█▄▄▄█▄▀▀░░░░▄████  ",
            "  ███████▄▄▄▄░░░░░░░░░░░░▄▄▄███████  ",
        },
        buttons = {
            { "  find file", "spc f f", "telescope find_files" },
            { "  recent files", "spc f o", "telescope oldfiles" },
            { "  find word", "spc f w", "telescope live_grep" },
            { "  bookmarks", "spc b m", "telescope marks" },
            { "  themes", "spc t h", "telescope themes" },
            { "  mappings", "spc c h", "nvcheatsheet" },
        },
    },
}
return M
