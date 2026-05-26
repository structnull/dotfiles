local config = {
    windows = {
        -- Gaming & Fullscreen
        { name = "fullscreen-apps", fullscreen = true, no_blur = true, match = { class = [[^(mpv|gamescope|soh\.elf)$]] } },
        { name = "mpv-content", content = "none", match = { class = [[^(mpv)$]] } },
        { name = "immediate-class", immediate = true, match = { class = [[^(cs2)$]] } },
        { name = "immediate-title", immediate = true, match = { title = [[^(glxgears|vkcubepp|hl_linux)$]] } },

        -- Media Players & UI Apps (Opacity & Grouping)
        { name = "opacity-chat", opacity = "0.70 0.60", match = { class = [[^(Spotify|vesktop)$]] } },
        { name = "opacity-tools", opacity = "0.85 0.80", match = { class = [[^(code-oss|codium|pcmanfm-qt|org.kde.polkit-kde-authentication-agent-1)$]] } },
        { name = "group-deny", group = "deny", match = { class = [[^(.*rnote.*|scrcpy)$]] } },

        -- General Floating & Dialogs 
        { name = "float-classes", float = true, match = { class = [[^(io\.github\.celluloid_player\.Celluloid|org\.kde\.kcalc|.*dialog.*|blobdrop|[Xx]dg-desktop-portal-(gtk|kde)|org\.freedesktop\.impl\.portal\.desktop\.kde)$]] } },
        { name = "float-titles", float = true, match = { title = [[^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress|File Upload.*|Choose wallpaper.*|Library.*|Media viewer.*|.*dialog.*|Progress Dialog — Dolphin|Copying — Dolphin|About Mozilla Firefox)$]] } },
        { name = "float-utility", float = true, center = true, match = { title = [[^(Preferences|Settings|Options|About)$]] } },
        { name = "float-modal", float = true, center = true, dim_around = true, match = { modal = true } },
        { name = "pip-windows", float = true, pin = true, match = { title = [[^(Picture-in-Picture)$]] } },

        -- Idle Inhibit
        { name = "idle-media-games", idle_inhibit = "focus", match = { class = [[^(mpv|.+exe|org\.kde\.haruna|looking-glass-client|gamescope|steam_app.*|steam_proton.*)$]] } },
        { name = "idle-yt", idle_inhibit = "focus", match = { class = [[^(firefox)$]], title = [[^(.*YouTube.*)$]] } },
        { name = "idle-fs", idle_inhibit = "focus", match = { class = [[^(firefox)$]], fullscreen = true } },

        -- Privacy / Screen Share Blocking
        { name = "no-share-classes", no_screen_share = true, match = { class = [[^(vesktop|org\.keepassxc\.KeePassXC)$]] } },
        { name = "no-share-titles", no_screen_share = true, match = { title = [[^(.*[Ww]hats[Aa]pp.*|.*\) Inbox|Inbox|All mail)(.*)$]] } },

        -- Workspaces
        { name = "discord-workspace", workspace = "5 silent", match = { title = [[^(.*(Disc|WebC)ord.*)$]] } },
        { name = "discord-sa-workspace", workspace = "5 silent", match = { class = [[^(de\.shorsh\.discord-screenaudio)$]] } },
        { name = "sharing-indicator", workspace = "special silent", match = { title = [[^(Firefox — Sharing Indicator|.*is sharing (your screen|a window)\.)$]] } },

        -- Specific Edge Cases & Fixes
        { name = "winecfg-no-max", no_max_size = true, match = { class = [[^(winecfg\.exe)$]] } },
        { name = "steam-minsize", min_size = { 1, 1 }, match = { class = [[^(steam)$]], title = [[^()$]] } },
        { name = "empty-noblur", no_blur = true, match = { class = [[^()$]], title = [[^()$]] } },
        { name = "suppress-maximize", suppress_event = "maximize", match = { class = ".*" } },
        { name = "xwayland-drag-fix", no_focus = true, match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false } },
        { name = "wall-picker", fullscreen = true, center = true, no_blur = false, stay_focused = true, animation = "slide", match = { class = [[^(wallpicker)$]] } },
        { name = "pinentry-focus", stay_focused = true, match = { class = [[(pinentry-)(.*)]] } },
    },

    layers = {
        { name = "qs-wallpaper", blur = false, ignore_alpha = 0.0, animation = "fade", order = 11, match = { namespace = [[^(qs_wallpaper)$]] } },
        { name = "interactive", blur = true, blur_popups = true, animation = "popin", ignore_alpha = 0.0, dim_around = true, order = 10, match = { namespace = [[^(rofi|vicinae)$]] } },
        { name = "ui-persistent", blur = true, ignore_alpha = 0.25, animation = "none", match = { namespace = [[^(qs_modules|waybar|swaync-control-center|logout_dialog)$]] } },
        { name = "notifications", blur = true, ignore_alpha = 0.35, animation = "slide", match = { namespace = [[^(swaync-notification-window)$]] } },
        { name = "no-screen-share", no_screen_share = true, match = { namespace = [[^(vicinae|swaync-control-center)$]] } },
    }
}


for _, rule in ipairs(config.windows) do
    hl.window_rule(rule)
end

for _, rule in ipairs(config.layers) do
    hl.layer_rule(rule)
end
