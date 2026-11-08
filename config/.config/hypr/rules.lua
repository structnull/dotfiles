local config = {
    windows = {
        -- Gaming & Fullscreen
        { name = "fullscreen-apps", fullscreen = true, no_blur = true, match = { class = [[^(mpv|gamescope|soh\.elf)$]] } },
        { name = "mpv-content", content = "none", match = { class = [[^(mpv)$]] } },
        { name = "immediate-class", immediate = true, match = { class = [[^(cs2)$]] } },
        { name = "immediate-title", immediate = true, match = { title = [[^(glxgears|vkcubepp|hl_linux)$]] } },

        -- Media Players & UI Apps (Opacity & Grouping)
        { name = "opacity-chat", opacity = "0.70 0.60", match = { class = [[^(Spotify|vesktop|io.github.yapfast.Yapfast)$]] } },
        { name = "opacity-tools", opacity = "0.75 0.80", match = { class = [[^(code-oss|md.obsidian.Obsidian|codium|pcmanfm-qt|org.kde.polkit-kde-authentication-agent-1)$]] } },
        { name = "group-deny", group = "deny", match = { class = [[^(.*rnote.*|scrcpy|speedynote)$]] } },

        -- General Floating & Dialogs 
        { name = "float-classes", float = true, match = { class = [[^(io\.github\.celluloid_player\.Celluloid|org\.kde\.kcalc|.*dialog.*|blobdrop|[Xx]dg-desktop-portal-(gtk|kde)|org\.freedesktop\.impl\.portal\.desktop\.kde)$]] } },
        { name = "float-titles", float = true, match = { title = [[^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress|File Upload.*|Choose wallpaper.*|Library.*|Media viewer.*|.*dialog.*|Progress Dialog — Dolphin|Copying — Dolphin|About Mozilla Firefox)$]] } },
        { name = "float-utility", float = true, center = true, match = { title = [[^(Preferences|Settings|Options|About)$]] } },
        { name = "float-modal", float = true, center = true, dim_around = true, match = { modal = true } },
        { name = "pip-windows", float = true, pin = true, keep_aspect_ratio = true, persistent_size = true, match = { title = [[^(Picture-in-Picture)$]] } },
        { name = "video-aspect", keep_aspect_ratio = true, match = { class = [[^(io\.github\.celluloid_player\.Celluloid)$]] } },

        -- Chromium extension popups (Bitwarden, etc.): class is chrome-<ext-id>-<profile>
        -- (older builds use crx_<ext-id>), initial title is _crx_<ext-id>. They must
        -- float and center at the known-good Bitwarden popout size, never tile.
        { name = "browser-extension-popups", float = true, center = true, match = { class = [[^(?:(?:chrome|chromium|brave|microsoft-edge)-[a-z]+-|crx_)]] } },

        -- Idle Inhibit
        { name = "idle-media-games", idle_inhibit = "focus", match = { class = [[^(mpv|.+exe|org\.kde\.haruna|looking-glass-client|gamescope|steam_app.*|steam_proton.*)$]] } },
        { name = "idle-yt", idle_inhibit = "focus", match = { class = [[^(firefox)$]], title = [[^(.*YouTube.*)$]] } },
        { name = "idle-fs", idle_inhibit = "focus", match = { class = [[^(firefox)$]], fullscreen = true } },

        -- Privacy / Screen Share Blocking
        { name = "no-share-classes", no_screen_share = true, match = { class = [[^(vesktop|org\.keepassxc\.KeePassXC)$]] } },
        { name = "no-share-titles", no_screen_share = true, match = { title = [[^(.*[Ww]hats[Aa]pp.*|.*\) Inbox|Inbox|All mail)(.*)$]] } },

        -- Workspaces
        { name = "special-scrolling-focused", scrolling_width = 1.0, match = { workspace = "special" } },
        { name = "discord-workspace", workspace = "5 silent", match = { title = [[^(.*(Disc|WebC)ord.*)$]] } },
        { name = "yapfast-workspace", workspace = "5 silent", match = { class = [[^io\.github\.yapfast\.Yapfast$]] } },
        { name = "sharing-indicator", workspace = "special silent", no_initial_focus = true, match = { title = [[^(Firefox — Sharing Indicator|.*is sharing (your screen|a window)\.)$]] } },

        -- Specific Edge Cases & Fixes
        { name = "winecfg-no-max", no_max_size = true, match = { class = [[^(winecfg\.exe)$]] } },
        { name = "steam-minsize", min_size = { 1, 1 }, match = { class = [[^(steam)$]], title = [[^()$]] } },
        { name = "empty-noblur", no_blur = true, match = { class = [[^()$]], title = [[^()$]] } },
        { name = "suppress-maximize", suppress_event = "maximize", match = { class = ".*" } },
        { name = "xwayland-drag-fix", no_focus = true, match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false } },
        { name = "wall-picker", fullscreen = true, center = true, no_blur = false, stay_focused = true, animation = "slide", match = { class = [[^(wallpicker)$]] } },
        { name = "pinentry-focus", stay_focused = true, match = { class = [[(pinentry-)(.*)]] } },
        { name = "float-persistent-size", persistent_size = true, match = { float = true } },
    },

    layers = {
        { name = "qs-wallpaper", blur = false, ignore_alpha = 0.0, animation = "fade", order = 11, match = { namespace = [[^(qs_wallpaper)$]] } },
        { name = "qs-polkit", blur = false, ignore_alpha = 0.25, animation = "fade", order = 12, match = { namespace = [[^(qs_polkit)$]] } },
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

local function watch_browser_popups(class_name, initial_title)
    hl.on("window.open", function(w)
        if not w or w.class ~= class_name then return end
        if w.initial_title ~= initial_title then return end

        local browser_windows = hl.get_windows({ class = class_name })
        if #browser_windows <= 1 then return end

        hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))

        local sub
        sub = hl.on("window.title", function(tw)
            if not tw or tw.address ~= w.address then return end
            if tw.title == ""
                or tw.title == initial_title
                or tw.title == "about:blank"
                or tw.title:match("^about:.*" .. initial_title .. "$") then return end

            sub:remove()

            if tw.title:match("^Extension:") then
                hl.dispatch(hl.dsp.window.resize({ x = 800, y = 600, window = tw }))
                hl.dispatch(hl.dsp.window.center({ window = tw }))
                hl.dispatch(hl.dsp.focus({ window = tw }))
            else
                hl.dispatch(hl.dsp.window.float({ action = "unset", window = tw }))
            end
        end)
    end)
end

watch_browser_popups("firefox", "Mozilla Firefox")
watch_browser_popups("helium", "New Tab - Helium")

-- Chromium extension popups open in their own window with a different class
-- (chrome-<ext-id>-<profile>) and initial title (_crx_<ext-id>), so they never
-- match watch_browser_popups. Float, center and focus them at map time; the
-- window rule above covers the geometry, this makes sure they get focus.
local function watch_extension_popups()
    hl.on("window.open", function(w)
        if not w or not w.class or not w.initial_title then return end

        -- Chromium extension popup class: chrome-<ext-id>-<profile> (or crx_<ext-id>)
        local is_chromium_ext = w.class:match("^chrome%-[a-z]+%-")
            or w.class:match("^chromium%-[a-z]+%-")
            or w.class:match("^brave%-[a-z]+%-")
            or w.class:match("^microsoft%-edge%-[a-z]+%-")
            or w.class:match("^crx_")
        if not is_chromium_ext then return end

        -- Extension popups always carry the _crx_<ext-id> initial title.
        if not w.initial_title:match("^_crx_") then return end

        hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
        hl.dispatch(hl.dsp.window.center({ window = w }))
        hl.dispatch(hl.dsp.focus({ window = w }))
    end)
end

watch_extension_popups()
