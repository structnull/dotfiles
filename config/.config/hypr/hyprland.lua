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

-- Settings
hl.config({
	input = {
		repeat_rate = 50,
		repeat_delay = 300,
		numlock_by_default = true,
		follow_mouse = 2,
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
		workspace_swipe_distance = 3000,
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
	},

	general = {
		allow_tearing = false,
		gaps_in = 2,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = {
				colors = {
					"rgba(7287fd77)",
					"rgba(b7bdf899)",
					"rgba(babbf166)",
					"rgba(b4befebb)",
				},
			},
			inactive_border = 0xFF313244,
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
			size = 8,
			passes = 4,
		},
	},

	render = {
		new_render_scheduling = true,
		direct_scanout = 0,
	},

	misc = {
		mouse_move_enables_dpms = true,
		vrr = 0,
		allow_session_lock_restore = true,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		always_follow_on_dnd = true,
		animate_mouse_windowdragging = true,
		animate_manual_resizes = true,
		layers_hog_keyboard_focus = true,
		focus_on_activate = true,
		initial_workspace_tracking = 0,
		close_special_on_empty = true,
	},

	dwindle = {
		preserve_split = true,
		force_split = 2,
		special_scale_factor = 0.8,
	},

	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.5,
		direction = "right",
	},
})

-- Curves
local curves = {
    snap      = { { 0.12, 1.00 }, { 0.22, 1.00 } },
    glide     = { { 0.25, 1.00 }, { 0.35, 1.00 } },
    fade      = { { 0.40, 0.00 }, { 0.20, 1.00 } },
    linear    = { { 0.00, 0.00 }, { 1.00, 1.00 } },
    overshoot = { { 0.34, 1.40 }, { 0.64, 1.00 } },
    decel     = { { 0.05, 0.70 }, { 0.10, 1.00 } },
    wsf       = { { 0.22, 1.00 }, { 0.36, 1.00 } },
    pop       = { { 0.23, 1.00 }, { 0.32, 1.00 } },
    softClose = { { 0.22, 1.00 }, { 0.36, 1.00 } },
    flowIn    = { { 0.16, 1.00 }, { 0.30, 1.00 } },
    flowOut   = { { 0.38, 0.00 }, { 0.58, 1.00 } }
}

for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

-- Animations
hl.animation({ leaf = "global", enabled = true, speed = 8.0, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 4.0, bezier = "snap" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.0, bezier = "snap", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.0, bezier = "pop", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "flowIn", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.0, bezier = "flowOut", style = "fade" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 3.0, bezier = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3.0, bezier = "fade" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "flowOut" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 8.0, bezier = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.2, bezier = "wsf", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5.0, bezier = "snap" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.0, bezier = "decel", style = "slidevert" })

-- Per-device config
hl.device({
	name = "at-translated-set-2-keyboard",
	kb_options = "ctrl:swapcaps",
})

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	hl.exec_cmd("qs ")
	hl.exec_cmd("vicinae server")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
	hl.exec_cmd("~/.scripts/gsettings.sh")
end)

require("keybinds")
require("rules")
