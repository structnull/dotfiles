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
    local layouts     = { "scrolling", "dwindle", "master", "monocle" }
    local workspace   = hl.get_active_workspace()
	if hl.get_active_special_workspace() then
		workspace = hl.get_active_special_workspace()
	end

    local next_layout = "dwindle"

    if not workspace then
        return
    end

    for i = 1, #layouts do
        if layouts[i] == workspace.tiled_layout then
            local next_layout_idx = (i % #layouts) + 1
            next_layout = layouts[next_layout_idx]
            break
        end
    end

	if workspace.special then
		hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout })
	else
		hl.workspace_rule({ workspace = tostring(workspace.id), layout = next_layout })
	end

	hl.exec_cmd("qs ipc call layout " .. next_layout)
end

-- =========================================================
-- Layout-aware actions
-- =========================================================
-- One key, four layouts. Dwindle keeps its old behavior; scrolling,
-- master and monocle get their native equivalent instead of a no-op.
--
--   ALT+T           split / join column / promote to master
--   ALT+hjkl        focus   (scroll tape, cycle stack, focus master)
--   ALT+SHIFT+hjkl  move    (swaps columns in scrolling)
--   ALT+CTRL+hjkl   resize  (column width in scrolling, mfact in master)
--   ALT+O           fit all (scrolling) / rotate master orientation
local function active_layout()
	local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
	return workspace and workspace.tiled_layout or "dwindle"
end

local function layout_bind(actions)
	return function()
		local action = actions[active_layout()]
		if action == nil then action = actions.dwindle end
		if type(action) == "function" then action = action() end
		if action then hl.dispatch(action) end
	end
end

-- Minimize to a scratch workspace, since Hyprland has no native minimize.
-- Pressing the key again restores the tagged window to the current workspace.
local function toggle_minimize()
	local minimized = hl.get_workspace("special:minimized")
	local active = hl.get_active_workspace()
	if not active then return end

	if minimized then
		hl.dispatch(hl.dsp.window.move({ workspace = active, window = "tag:minimized" }))
		hl.dispatch(hl.dsp.window.clear_tags({ window = "tag:minimized" }))
	else
		local window = hl.get_active_window()
		if not window then return end
		hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = window }))
		hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
	end
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
    { "XF86ScreenSaver", toggle_lock, { submap_universal = true } },
    { SS .. " + L", cmd("qs ipc call power toggleOverlay") },
    { SCS .. " + Q", hl.dsp.exit() },
    { S .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }) },
    { MS .. " + R", hl.dsp.force_renderer_reload() },

    -- Screenshots, Recording & Scripts
    { MS .. " + S", cmd("~/.scripts/grim_ocr.sh") },
    { SS .. " + S", cmd("~/.scripts/ss.sh") },
    { "Print", cmd("~/.scripts/grimblast.sh --notify copysave"), { submap_universal = true } },
    { SC .. " + R", cmd("~/.scripts/record-screen.sh") },
    { SC .. " + P", cmd("~/.scripts/dec.sh") },
    { SS .. " + P", cmd("~/.scripts/wf-freeze.sh -a") },

    -- Layout & Window Control
    { M .. " + S", hl.dsp.window.float({ action = "toggle" }) },
    { M .. " + space", function()
        local window = hl.get_active_window()
        if not window then return end
        hl.dispatch(hl.dsp.window.cycle_next({
            floating = not window.floating,
            tiled = window.floating,
        }))
    end, { description = "Switch focus between tiled and floating windows" } },
    { S .. " + M", toggle_minimize, { description = "Minimize window to special workspace" } },
    { M .. " + T", layout_bind({
        dwindle   = hl.dsp.layout("togglesplit"),        -- flip split direction
        scrolling = hl.dsp.layout("consume_or_expel prev"), -- join column / pop out
        master    = hl.dsp.layout("swapwithmaster"),     -- promote to master
        monocle   = false,                               -- nothing to split
    }), { description = "Split / join column / promote to master" } },
    { M .. " + I", hl.dsp.layout("fit active") },
    { M .. " + O", layout_bind({
        scrolling = hl.dsp.layout("fit all"),          -- zoom out to every column
        master    = hl.dsp.layout("orientationnext"),  -- rotate master area
        dwindle   = false,
        monocle   = false,
    }), { description = "Fit all (scrolling) / rotate master" } },
    { M .. " + Q", hl.dsp.window.close() },
    { S .. " + P", toggle_layout },

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
    { "XF86AudioRaiseVolume", cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = true, submap_universal = true } },
    { "XF86AudioLowerVolume", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = true, submap_universal = true } },
    { "XF86MonBrightnessUp", cmd("brightnessctl set 2%+"), { repeating = true, submap_universal = true } },
    { "XF86MonBrightnessDown", cmd("brightnessctl set 2%-"), { repeating = true, submap_universal = true } },
    { M .. " + KP_Add", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") },
    { M .. " + KP_Subtract", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },

    -- Mute Toggles
    { "XF86AudioMute", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { submap_universal = true } },
    { M .. " + M", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
    { "XF86AudioMicMute", cmd("~/.scripts/mic.sh"), { submap_universal = true } },
    { M .. " + X", cmd("~/.scripts/mic.sh") },

    -- Zoom adjustments
    { MC .. " + mouse_up", function() change_zoom(2.0) end },
    { MC .. " + mouse_down", function() change_zoom(0.5) end },
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
        hl.bind(k, cmd("~/.scripts/playerctl.sh " .. act), {
            submap_universal = k:match("^XF86") ~= nil,
        })
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
        -- Focus: scrolling pans the tape; master/monocle cycle their stacks.
        hl.bind(M .. " + " .. k, layout_bind({
            dwindle   = hl.dsp.focus({ direction = d.dir }),
            scrolling = (d.dir == "l" or d.dir == "r")
                and hl.dsp.layout("focus " .. d.dir)
                or hl.dsp.focus({ direction = d.dir }),
            master    = (d.dir == "l") and hl.dsp.layout("focusmaster")
                or (d.dir == "u") and hl.dsp.layout("cycleprev")
                or hl.dsp.layout("cyclenext"),
            monocle   = (d.dir == "l" or d.dir == "u")
                and hl.dsp.layout("cycleprev")
                or hl.dsp.layout("cyclenext"),
        }), { description = "Focus (layout-aware)" })

        -- Move: scrolling swaps whole columns instead of nudging a window.
        hl.bind(MS .. " + " .. k, layout_bind({
            dwindle   = hl.dsp.window.move({ direction = d.dir }),
            scrolling = (d.dir == "l") and hl.dsp.layout("swapcol l")
                or (d.dir == "r") and hl.dsp.layout("swapcol r")
                or hl.dsp.window.move({ direction = d.dir }),
            master    = hl.dsp.window.move({ direction = d.dir }),
            monocle   = false, -- every window already fills the screen
        }), { description = "Move window (layout-aware)" })

        -- Resize: scrolling changes column width, master changes mfact.
        hl.bind(MC .. " + " .. k, layout_bind({
            dwindle   = hl.dsp.window.resize({ x = d.rx, y = d.ry, relative = true }),
            scrolling = (d.dir == "l") and hl.dsp.layout("colresize -0.05")
                or (d.dir == "r") and hl.dsp.layout("colresize +0.05")
                or false,
            master    = (d.dir == "l") and hl.dsp.layout("mfact -0.05")
                or (d.dir == "r") and hl.dsp.layout("mfact +0.05")
                or false,
            monocle   = false,
        }), { repeating = (k:len() == 1), description = "Resize (layout-aware)" })
    end
end

-- =========================================================
-- Submaps
-- =========================================================
hl.bind(S .. " + Escape", hl.dsp.submap("passthru"))
hl.define_submap("passthru", function()
    hl.bind(S .. " + Escape", hl.dsp.submap("reset"))
end)



-- Adjust volume
local volume_gesture = function(change) hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. math.abs(change) .. "%" .. (change<0 and "-" or "+")) end
hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = {
        start = function(e) volume_gesture(-0.25 * e.delta.y) end,
        update = function(e) volume_gesture(-0.25 * e.delta.y) end
    }
})

