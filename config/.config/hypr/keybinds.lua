local M = "ALT"
local MS = M .. " + SHIFT"
local MC = M .. " + CONTROL"
local S = "SUPER"
local SS = S .. " + SHIFT"
local SC = S .. " + CONTROL"
local SCS = S .. " + CONTROL + SHIFT"
local CS = "CONTROL + SHIFT"

local function set_zoom_factor(value)
    hl.config({
        cursor = {
            zoom_factor = math.max(1, value),
        },
    })
end

local function change_zoom_factor(multiplier)
    local current = hl.get_config("cursor.zoom_factor")
    if type(current) ~= "number" then
        current = 1
    end

    set_zoom_factor(current * multiplier)
end

-- Application launchers
hl.bind(S .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(S .. " + F", hl.dsp.exec_cmd("helium-browser"))
hl.bind(S .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("kcalc"))
hl.bind(S .. " + C", hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind(S .. " + period", hl.dsp.exec_cmd("vicinae vicinae://launch/core/search-emojis"))
hl.bind(S .. " + space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(SC .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
hl.bind(CS .. " + Escape", hl.dsp.exec_cmd("plasma-systemmonitor"))

-- System and session control
hl.bind("XF86ScreenSaver", function()
    hl.exec_cmd("$HOME/.scripts/lock.sh")
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "disable" }))
    end, { timeout = 1000, type = "oneshot" })
end)
hl.bind(SS .. " + L", hl.dsp.exec_cmd("qs ipc call power toggleOverlay"))
hl.bind(SCS .. " + Q", hl.dsp.exit())
hl.bind(S .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(MS .. " + R", hl.dsp.force_renderer_reload())

-- Screenshots and recording
hl.bind(MS .. " + S", hl.dsp.exec_cmd("~/.scripts/grim_ocr.sh"))
hl.bind(SS .. " + S", hl.dsp.exec_cmd("~/.scripts/ss.sh"))
hl.bind("Print", hl.dsp.exec_cmd("~/.scripts/grimblast.sh --notify copysave"))
hl.bind(SC .. " + R", hl.dsp.exec_cmd("~/.scripts/record-screen.sh"))

-- Custom scripts
hl.bind(SC .. " + P", hl.dsp.exec_cmd("~/.scripts/dec.sh"))
hl.bind(SS .. " + P", hl.dsp.exec_cmd("~/.scripts/wf-freeze.sh -a"))

-- Zoom controls
hl.bind(MC .. " + mouse_down", function() change_zoom_factor(2.0) end)
hl.bind(MC .. " + mouse_up", function() change_zoom_factor(0.5) end)
hl.bind(M .. " + equal", function() change_zoom_factor(1.1) end, { repeating = true })
hl.bind(M .. " + minus", function() change_zoom_factor(0.9) end, { repeating = true })
hl.bind(M .. " + KP_ADD", function() change_zoom_factor(1.1) end, { repeating = true })
hl.bind(M .. " + KP_SUBTRACT", function() change_zoom_factor(0.9) end, { repeating = true })
hl.bind(MS .. " + mouse_up", function() set_zoom_factor(1) end)
hl.bind(MS .. " + mouse_down", function() set_zoom_factor(1) end)
hl.bind(MS .. " + minus", function() set_zoom_factor(1) end)
hl.bind(MS .. " + KP_SUBTRACT", function() set_zoom_factor(1) end)
hl.bind(MS .. " + 0", function() set_zoom_factor(1) end)

-- VM passthrough submap
hl.bind(S .. " + Escape", hl.dsp.submap("passthru"))
hl.define_submap("passthru", function()
    hl.bind(S .. " + Escape", hl.dsp.submap("reset"))
end)

-- Mouse bindings
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(S .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Audio, mic, and brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(M .. " + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("~/.scripts/mic.sh"))
hl.bind(M .. " + X", hl.dsp.exec_cmd("~/.scripts/mic.sh"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 2%-"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 2%+"), { repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("~/.scripts/playerctl.sh play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("~/.scripts/playerctl.sh next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("~/.scripts/playerctl.sh previous"))
hl.bind(M .. " + KP_5", hl.dsp.exec_cmd("~/.scripts/playerctl.sh play-pause"))
hl.bind(M .. " + KP_6", hl.dsp.exec_cmd("~/.scripts/playerctl.sh next"))
hl.bind(M .. " + KP_4", hl.dsp.exec_cmd("~/.scripts/playerctl.sh previous"))
hl.bind(M .. " + KP_Begin", hl.dsp.exec_cmd("~/.scripts/playerctl.sh play-pause"))
hl.bind(M .. " + KP_Left", hl.dsp.exec_cmd("~/.scripts/playerctl.sh previous"))
hl.bind(M .. " + KP_Right", hl.dsp.exec_cmd("~/.scripts/playerctl.sh next"))
hl.bind(M .. " + period", hl.dsp.exec_cmd("~/.scripts/playerctl.sh play-pause"))
hl.bind(M .. " + comma", hl.dsp.exec_cmd("~/.scripts/playerctl.sh previous"))
hl.bind(M .. " + slash", hl.dsp.exec_cmd("~/.scripts/playerctl.sh next"))
hl.bind(M .. " + KP_Add", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind(M .. " + KP_Subtract", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))

-- Workspaces
for i = 1, 9 do
    hl.bind(M .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(MS .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(M .. " + D", hl.dsp.workspace.toggle_special(""))
hl.bind(MS .. " + D", hl.dsp.window.move({ workspace = "special" }))

-- Window and tiling control
hl.bind(S .. " + P", function()
    local l = hl.get_config("general:layout") == "scrolling"
        and "dwindle" or "scrolling"
    hl.config({ general = { layout = l } })
    hl.notification.create({
        text = "Switched to " .. l .. " layout",
        duration = 1000,
    })
end)

hl.bind(M .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + T", hl.dsp.layout("togglesplit"))

-- Scrolling layout controls
hl.bind(M .. " + I", hl.dsp.layout("fit active"))
hl.bind(M .. " + O", hl.dsp.layout("fit all"))
hl.bind(S .. " + apostrophe", hl.dsp.layout("consume_or_expel prev"))
hl.bind(S .. " + semicolon", hl.dsp.layout("consume_or_expel next"))
hl.bind(M .. " + Q", hl.dsp.window.close())

hl.bind(S .. " + tab", hl.dsp.group.toggle())
hl.bind(M .. " + tab", hl.dsp.group.next())

hl.bind(M .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(M .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(M .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(M .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(M .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(M .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(M .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(M .. " + j", hl.dsp.focus({ direction = "d" }))

hl.bind(MS .. " + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(MS .. " + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(MS .. " + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(MS .. " + J", hl.dsp.window.move({ direction = "d" }))

hl.bind(MC .. " + up", hl.dsp.focus({ monitor = "l" }))
hl.bind(MC .. " + down", hl.dsp.focus({ monitor = "r" }))

hl.bind(MC .. " + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(MC .. " + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(MC .. " + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(MC .. " + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
hl.bind(MC .. " + h", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(MC .. " + l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(MC .. " + k", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(MC .. " + j", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Group navigation
hl.bind(M .. " + up", hl.dsp.group.next())
hl.bind(M .. " + down", hl.dsp.group.prev())

