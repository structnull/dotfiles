-- Gaming and fullscreen behavior
hl.window_rule({
    name = "fullscreen",
    match = { class = [[^(mpv|gamescope|soh\.elf)$]] },
    fullscreen = true,
    no_blur = true,
})

hl.window_rule({
    name = "mpv_content",
    match = { class = [[^(mpv)$]] },
    content = "none",
})

hl.window_rule({
    name = "cs2",
    match = { class = [[^(cs2)$]] },
    immediate = true,
})

hl.window_rule({
    name = "benchmark-immediate",
    match = { title = [[^(glxgears|vkcubepp|hl_linux)$]] },
    immediate = true,
})

-- Media players
hl.window_rule({
    name = "media-players",
    match = { class = [[^(io\.github\.celluloid_player\.Celluloid)$]] },
    float = true,
})

-- Opacity
hl.window_rule({
    name = "opacity-chat",
    match = { class = [[^(Spotify|vesktop)$]] },
    opacity = "0.70 0.60",
})

hl.window_rule({
    name = "opacity",
    match = { class = [[^(code-oss|codium|pcmanfm-qt|org.kde.polkit-kde-authentication-agent-1)$]] },
    opacity = "0.85 0.80",
})

-- Special window behavior
hl.window_rule({ name = "winecfg-no-max-size", match = { class = [[^(winecfg\.exe)$]] }, no_max_size = true })
hl.window_rule({ name = "rnote-no-group", match = { class = [[^(.*rnote.*)$]] }, group = "deny" })
hl.window_rule({ name = "scrcpy-no-group", match = { class = [[^(scrcpy)$]] }, group = "deny" })
hl.window_rule({ name = "kcalc-float", match = { class = [[^(org.kde.kcalc)$]] }, float = true })

-- Common modal dialogs
hl.window_rule({
    name = "modal-dialogs",
    match = { title = [[^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$]] },
    float = true,
})

hl.window_rule({
    name = "file-dialogs",
    match = { title = [[^(File Upload|Choose wallpaper|Library|Media viewer)(.*)$]] },
    float = true,
})

hl.window_rule({
    name = "dialog-titles",
    match = { title = [[^(.*dialog.*)$]] },
    float = true,
})

hl.window_rule({
    name = "portal-dialogs",
    match = { class = [[^([Xx]dg-desktop-portal-(gtk|kde)|org.freedesktop.impl.portal.desktop.kde)$]] },
    float = true,
})

hl.window_rule({
    name = "dialog-classes",
    match = { class = [[^(.*dialog.*)$]] },
    float = true,
})

hl.window_rule({
    name = "pip-windows",
    match = { title = [[^(Picture-in-Picture)$]] },
    float = true,
    pin = true,
})

hl.window_rule({
    name = "float-dialogs",
    match = { modal = true },
    float = true,
    center = true,
    dim_around = true,
})

hl.window_rule({
    name = "float-utility",
    match = { title = [[^(Preferences|Settings|Options|About)$]] },
    float = true,
    center = true,
})

hl.window_rule({
    name = "dolphin-progress",
    match = {
        class = [[^(org.kde.dolphin)$]],
        title = [[^(Progress Dialog — Dolphin|Copying — Dolphin)$]],
    },
    float = true,
})

-- Firefox
hl.window_rule({
    name = "firefox-float",
    match = {
        class = [[^(firefox)$]],
        title = [[^(About Mozilla Firefox|Picture-in-Picture|Library)$]],
    },
    float = true,
})

hl.window_rule({
    name = "firefox-sharing-indicator",
    match = {
        class = [[^(firefox)$]],
        title = [[^(Firefox — Sharing Indicator)$]],
    },
    workspace = "special silent",
})

hl.window_rule({
    name = "sharing-indicator-generic",
    match = { title = [[^(.*is sharing (your screen|a window)\.)$]] },
    workspace = "special silent",
})

hl.window_rule({
    name = "firefox-youtube-idle",
    match = {
        class = [[^(firefox)$]],
        title = [[^(.*YouTube.*)$]],
    },
    idle_inhibit = "focus",
})

hl.window_rule({
    name = "firefox-fullscreen-idle",
    match = {
        class = [[^(firefox)$]],
        fullscreen = true,
    },
    idle_inhibit = "focus",
})

-- Screen share blocking
hl.window_rule({
    name = "no-share-apps",
    match = { class = [[^(vesktop|org.keepassxc.KeePassXC)$]] },
    no_screen_share = true,
})

hl.window_rule({
    name = "no-share-whatsapp",
    match = { title = [[^(.*[Ww]hats[Aa]pp.*)$]] },
    no_screen_share = true,
})

hl.window_rule({
    name = "no-share-inbox",
    match = { title = [[^(.*)(\) Inbox|Inbox|All mail)(.*)$]] },
    no_screen_share = true,
})

-- Idle inhibit
hl.window_rule({
    name = "idle-inhibit-media",
    match = { class = [[^(mpv|.+exe|org.kde.haruna|looking-glass-client|gamescope)$]] },
    idle_inhibit = "focus",
})

hl.window_rule({
    name = "idle-inhibit-steam",
    match = { class = [[^(steam_app.*|steam_proton.*)$]] },
    idle_inhibit = "focus",
})

hl.window_rule({
    name = "looking-glass-fullscreen",
    match = {
        class = [[^(looking-glass-client)$]],
        fullscreen = true,
    },
    idle_inhibit = "focus",
})

-- Communication apps
hl.window_rule({
    name = "discord-workspace",
    match = { title = [[^(.*(Disc|WebC)ord.*)$]] },
    workspace = "5 silent",
})

hl.window_rule({
    name = "discord-screenaudio-workspace",
    match = { class = [[^(de.shorsh.discord-screenaudio)$]] },
    workspace = "5 silent",
})

-- Steam fixes
hl.window_rule({
    name = "steam-minsize",
    match = {
        title = [[^()$]],
        class = [[^(steam)$]],
    },
    min_size = { 1, 1 },
})

hl.window_rule({
    name = "empty-window-noblur",
    match = {
        class = [[^()$]],
        title = [[^()$]],
    },
    no_blur = true,
})

-- Global fixes
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "xwayland-drag-fix",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "wall-paper-picker",
    match = { class = [[^(wallpicker)$]] },
    fullscreen = true,
    center = true,
    no_blur = false,
    stay_focused = true,
    animation = "slide",
})

hl.window_rule({
    name = "pinentry-focus",
    match = { class = [[(pinentry-)(.*)]] },
    stay_focused = true,
})

-- Layer rules
hl.layer_rule({
    name = "qs-wallpaper",
    match = { namespace = [[^(qs_wallpaper)$]] },
    blur = false,
    ignore_alpha = 0.0,
    animation = "fade",
    order = 11,
})

hl.layer_rule({
    name = "interactive",
    match = { namespace = [[^(rofi|vicinae)$]] },
    blur = true,
    blur_popups = true,
    animation = "popin",
    ignore_alpha = 0.0,
    dim_around = true,
    order = 10,
})

hl.layer_rule({
    name = "ui-persistent",
    match = { namespace = [[^(qs_modules|waybar|swaync-control-center|logout_dialog)$]] },
    blur = true,
    ignore_alpha = 0.25,
    animation = "none",
})

hl.layer_rule({
    name = "notifications",
    match = { namespace = [[^(swaync-notification-window)$]] },
    blur = true,
    ignore_alpha = 0.35,
    animation = "slide",
})

hl.layer_rule({
    name = "no-screen-share",
    match = { namespace = [[^(vicinae|swaync-control-center)$]] },
    no_screen_share = true,
})
