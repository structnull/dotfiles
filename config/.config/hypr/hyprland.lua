-- Environment Variables
local env = {
	HYPRCURSOR_SIZE = "24",
	XCURSOR_SIZE = "24",
	XCURSOR_THEME = "BreezeX-RoséPine-Linux",
	HYPRCURSOR_THEME = "rose-pine-hyprcursor",
	GDK_BACKEND = "wayland,x11",
	MOZ_ENABLE_WAYLAND = "1",
	QT_QPA_PLATFORM = "wayland;xcb",
	QT_QPA_PLATFORMTHEME = "qt6ct",
	QT_AUTO_SCREEN_SCALE_FACTOR = "1",
	QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
	QT_QUICK_CONTROLS_STYLE = "org.kde.desktop",
	XDG_SESSION_TYPE = "wayland",
	XDG_SESSION_DESKTOP = "Hyprland",
	XDG_CURRENT_DESKTOP = "Hyprland",
	XDG_MENU_PREFIX = "plasma-",
	_JAVA_AWT_WM_NONREPARENTING = "1",
}

for k, v in pairs(env) do
	hl.env(k, v)
end

-- Monitors
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

-- Workspaces 1-4 on eDP-1, 5-8 on HDMI-A-1
for i = 1, 8 do
	hl.workspace_rule({ workspace = tostring(i), monitor = i <= 4 and "eDP-1" or "HDMI-A-1" })
end

-- Inset special workspaces as a workspace-rule replacement for special_scale_factor.
hl.workspace_rule({ workspace = "s[true]", gaps_out = 40 })

-- Settings
hl.config({
	input = {
		repeat_rate = 50,
		repeat_delay = 300,
		numlock_by_default = true,
		follow_mouse = 2,
		focus_on_close = 2,
		sensitivity = 1,

		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			clickfinger_behavior = true,
			middle_button_emulation = true,
			tap_to_click = true,
			tap_and_drag = true,
		},
	},

	gestures = {
		workspace_swipe_distance = 2000,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = false,
		workspace_swipe_forever = true,
	},

	debug = {
		overlay = false,
	},

	cursor = {
		no_hardware_cursors = 0,
		warp_on_toggle_special = 1,
	},

	general = {
		allow_tearing = false,
		gaps_in = 2,
		gaps_out = 8,
		float_gaps = 8,
		border_size = 2,
		resize_on_border = true,
		extend_border_grab_area = 15,
		hover_icon_on_border = true,
		snap = {
			enabled = true,
			respect_gaps = true,
		},
		col = {
			active_border = {
				colors = {
					"rgba(7287fd77)",
					"rgba(b7bdf899)",
					"rgba(babbf166)",
					"rgba(b4befebb)",
				},
			},
            inactive_border = "rgba(313244ff)",
		},
	},

	binds = {
		hide_special_on_workspace_change = true,
		allow_pin_fullscreen = true,
		movefocus_cycles_groupfirst = true,
	},

	group = {
		groupbar = {
			disable_when_only = true,
		},
	},

	animations = {
		enabled = true,
	},

	decoration = {
		rounding = 16,
		rounding_power = 4,
		dim_inactive = true,
		dim_strength = 0.3,
		dim_special = 0.6,

		shadow = {
			enabled = false,
		},

		blur = {
			special = false,
			enabled = true,
			popups = true,
			popups_ignorealpha = 0.4,
			new_optimizations = true,
			noise = 0,
			ignore_opacity = true,
			size = 3,
			passes = 4,
		},
	},

	render = {
		new_render_scheduling = true,
		direct_scanout = 0,
	},

	layers = {
		layers_hog_keyboard_focus = true,
	},

	misc = {
		mouse_move_enables_dpms = true,
		vrr = 0,
		allow_session_lock_restore = true,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		always_follow_on_dnd = true,
		animate_mouse_windowdragging = false,
		animate_manual_resizes = false,

		focus_on_activate = true,
		initial_workspace_tracking = 0,
		close_special_on_empty = true,
	},

	dwindle = {
		preserve_split = true,
		force_split = 2,
	},

	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.5,
		direction = "right",
	},
})

-- Curves
-- Springs use mass = 1. The damping ratio is zeta = damping / (2 * sqrt(stiffness)):
--   zeta = 1.0  critically damped, settles fast and never overshoots (Apple ".smooth")
--   zeta < 1.0  slight overshoot / bounce
-- Springs ignore `speed`. Settle time is roughly 2*pi/sqrt(stiffness) seconds.
local springs = {
    window = { stiffness = 320, damping = 35.78 },  -- zeta 1.00, ~350 ms
    move   = { stiffness = 400, damping = 40.00 },  -- zeta 1.00, ~314 ms
    space  = { stiffness = 260, damping = 32.25 },  -- zeta 1.00, ~390 ms
    zoom   = { stiffness = 300, damping = 34.64 },  -- zeta 1.00, ~363 ms
    -- Workspace crossfade is asymmetric on purpose: the incoming workspace
    -- resolves first, the outgoing one dissolves underneath it. Equal
    -- durations wash out to a muddy 50/50 blend mid-transition.
    wsIn   = { stiffness = 280, damping = 33.47 },  -- zeta 1.00, ~375 ms
    wsOut  = { stiffness = 200, damping = 28.28 },  -- zeta 1.00, ~444 ms
}

for name, s in pairs(springs) do
    hl.curve(name, { type = "spring", mass = 1, stiffness = s.stiffness, damping = s.damping })
end

local curves = {
    easeOut = { { 0.22, 1.00 }, { 0.36, 1.00 } },  -- easeOutQuint
    linear  = { { 0.00, 0.00 }, { 1.00, 1.00 } },
}

for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

-- Animations
-- `speed` on a spring leaf is ignored by Hyprland; it is kept only as the
-- intended settle time in deciseconds so the numbers stay meaningful.
hl.animation({ leaf = "global", enabled = true, speed = 3.0, bezier = "easeOut" })

hl.animation({ leaf = "windows", enabled = true, speed = 3.5, spring = "window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, spring = "window", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear", style = "popin 88%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.1, spring = "move" })

hl.animation({ leaf = "fade", enabled = true, speed = 2.0, bezier = "linear" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.6, bezier = "linear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.3, bezier = "linear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 1.8, bezier = "easeOut" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 8.0, bezier = "linear" })

hl.animation({ leaf = "layers", enabled = true, speed = 2.4, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.4, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 2.0, bezier = "linear" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.8, bezier = "linear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.4, bezier = "linear" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 2.4, spring = "wsIn", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.3, spring = "wsIn", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.9, spring = "wsOut", style = "fade" })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.9, spring = "space", style = "slidevert" })

hl.animation({ leaf = "border", enabled = true, speed = 2.0, bezier = "easeOut" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3.6, spring = "zoom" })

-- Per-device config
hl.device({
	name = "at-translated-set-2-keyboard",
	kb_options = "ctrl:swapcaps",
})

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })
-- Scrolling layout only: pan the tape with a four-finger swipe.
hl.gesture({ fingers = 4, direction = "horizontal", action = "scroll_move" })

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE")
	hl.exec_cmd("systemctl --user start hyprland-session.target")
	hl.exec_cmd("qs")
	hl.exec_cmd("vicinae server")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
	hl.exec_cmd("~/.scripts/gsettings.sh")
end)

hl.on("hyprland.shutdown", function()
	os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)

require("keybinds")
require("rules")
