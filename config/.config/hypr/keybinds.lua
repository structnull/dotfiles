local M, MS, MC = "ALT", "ALT + SHIFT", "ALT + CONTROL"
local S, SS, SC, SCS = "SUPER", "SUPER + SHIFT", "SUPER + CONTROL", "SUPER + CONTROL + SHIFT"
local CS = "CONTROL + SHIFT"
local cmd = hl.dsp.exec_cmd

local function set_zoom(value)
    hl.config({ cursor = { zoom_factor = math.max(1, value) } })
end

local function change_zoom(multiplier)
    local current = hl.get_config("cursor.zoom_factor")
    set_zoom((type(current) == "number" and current or 1) * multiplier)
end

local function toggle_lock()
    hl.exec_cmd("$HOME/.scripts/lock.sh")
    hl.timer(function() hl.dispatch(hl.dsp.dpms({ action = "disable" })) end, { timeout = 1000, type = "oneshot" })
end

local function toggle_layout()
    local layout = hl.get_config("general:layout") == "scrolling" and "dwindle" or "scrolling"
    hl.config({ general = { layout = layout } })
    hl.notification.create({ text = "Switched to " .. layout .. " layout", duration = 1000 })
end

-- =========================================================
-- General Keybindings Configuration
-- =========================================================
local binds = {
    -- Applications
    { S .. " + Return", cmd("kitty") },
    { S .. " + F", cmd("helium-browser") },
    { S .. " + E", cmd("dolphin") },
    { S .. " + C", cmd("vicinae vicinae://launch/clipboard/history") },
    { S .. " + period", cmd("vicinae vicinae://launch/core/search-emojis") },
    { S .. " + space", cmd("vicinae toggle") },
    { "XF86Calculator", cmd("kcalc") },
    { CS .. " + Escape", cmd("plasma-systemmonitor") },
    { SC .. " + W", cmd("qs ipc call wallpaper toggle") },

    -- System & Session
    { "XF86ScreenSaver", toggle_lock },
    { SS .. " + L", cmd("qs ipc call power toggleOverlay") },
    { SCS .. " + Q", hl.dsp.exit() },
    { S .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }) },
    { MS .. " + R", hl.dsp.force_renderer_reload() },

    -- Screenshots, Recording & Scripts
    { MS .. " + S", cmd("~/.scripts/grim_ocr.sh") },
    { SS .. " + S", cmd("~/.scripts/ss.sh") },
    { "Print", cmd("~/.scripts/grimblast.sh --notify copysave") },
    { SC .. " + R", cmd("~/.scripts/record-screen.sh") },
    { SC .. " + P", cmd("~/.scripts/dec.sh") },
    { SS .. " + P", cmd("~/.scripts/wf-freeze.sh -a") },

    -- Layout & Window Control
    { M .. " + S", hl.dsp.window.float({ action = "toggle" }) },
    { M .. " + T", hl.dsp.layout("togglesplit") },
    { M .. " + I", hl.dsp.layout("fit active") },
    { M .. " + O", hl.dsp.layout("fit all") },
    { M .. " + Q", hl.dsp.window.close() },
    { S .. " + P", toggle_layout },
    { S .. " + apostrophe", hl.dsp.layout("consume_or_expel prev") },
    { S .. " + semicolon", hl.dsp.layout("consume_or_expel next") },

    -- Groups
    { S .. " + tab", hl.dsp.group.toggle() },
    { M .. " + tab", hl.dsp.group.next() },
    { M .. " + up", hl.dsp.group.next() },
    { M .. " + down", hl.dsp.group.prev() },

    -- Monitors 
    { MC .. " + up", hl.dsp.focus({ monitor = "l" }) },
    { MC .. " + down", hl.dsp.focus({ monitor = "r" }) },

    -- Special Workspaces & Mouse Target Focus
    { M .. " + D", hl.dsp.workspace.toggle_special("") },
    { MS .. " + D", hl.dsp.window.move({ workspace = "special" }) },
    { S .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }) },
    { S .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }) },

    -- Mouse actions
    { M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true } },
    { M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true } },

    -- Volume & Brightness
    { "XF86AudioRaiseVolume", cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = true } },
    { "XF86AudioLowerVolume", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = true } },
    { "XF86MonBrightnessUp", cmd("brightnessctl set 2%+"), { repeating = true } },
    { "XF86MonBrightnessDown", cmd("brightnessctl set 2%-"), { repeating = true } },
    { M .. " + KP_Add", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") },
    { M .. " + KP_Subtract", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },

    -- Mute Toggles
    { "XF86AudioMute", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
    { M .. " + M", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
    { "XF86AudioMicMute", cmd("~/.scripts/mic.sh") },
    { M .. " + X", cmd("~/.scripts/mic.sh") },

    -- Zoom adjustments
    { MC .. " + mouse_down", function() change_zoom(2.0) end },
    { MC .. " + mouse_up", function() change_zoom(0.5) end },
    { M .. " + equal", function() change_zoom(1.1) end, { repeating = true } },
    { M .. " + minus", function() change_zoom(0.9) end, { repeating = true } },
    { M .. " + KP_ADD", function() change_zoom(1.1) end, { repeating = true } },
    { M .. " + KP_SUBTRACT", function() change_zoom(0.9) end, { repeating = true } },
}

-- Execute single keybinds
for _, b in ipairs(binds) do hl.bind(b[1], b[2], b[3]) end

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(M .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(MS .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Reset Zoom factors
for _, key in ipairs({ "mouse_up", "mouse_down", "minus", "KP_SUBTRACT", "0" }) do
    hl.bind(MS .. " + " .. key, function() set_zoom(1) end)
end

-- Media Control Multiplexer
local media = {
    ["play-pause"] = { "XF86AudioPlay", M.."+KP_5", M.."+KP_Begin", M.."+period" },
    ["next"]       = { "XF86AudioNext", M.."+KP_6", M.."+KP_Right", M.."+slash" },
    ["previous"]   = { "XF86AudioPrev", M.."+KP_4", M.."+KP_Left", M.."+comma" }
}
for act, keys in pairs(media) do
    for _, k in ipairs(keys) do
        hl.bind(k, cmd("~/.scripts/playerctl.sh " .. act))
    end
end

-- Directional Matrix (Focus, Move, Resize via Vim & Arrow keys)
local dirs = {
    { keys = {"h", "left"}, dir = "l", rx = -20, ry = 0 },
    { keys = {"l", "right"}, dir = "r", rx = 20, ry = 0 },
    { keys = {"k", "up"}, dir = "u", rx = 0, ry = -20 },
    { keys = {"j", "down"}, dir = "d", rx = 0, ry = 20 },
}

for _, d in ipairs(dirs) do
    for _, k in ipairs(d.keys) do
        hl.bind(M .. " + " .. k, hl.dsp.focus({ direction = d.dir }))
        hl.bind(MS .. " + " .. k, hl.dsp.window.move({ direction = d.dir }))
        hl.bind(MC .. " + " .. k, hl.dsp.window.resize({ x = d.rx, y = d.ry, relative = true }), { repeating = (k:len() == 1) })
    end
end

-- =========================================================
-- Submaps
-- =========================================================
hl.bind(S .. " + Escape", hl.dsp.submap("passthru"))
hl.define_submap("passthru", function()
    hl.bind(S .. " + Escape", hl.dsp.submap("reset"))
end)
