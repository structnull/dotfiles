#!/bin/bash
# Auto-map OpenTabletDriver tablet region to Rnote window in Hyprland (Wayland socket path)

tablet_config="$HOME/.config/OpenTabletDriver/settings.json"
rnote_class="com.github.flxzt.rnote"
tablet_name="opentabletdriver-virtual-artist-tablet"

# Detect the correct Hyprland socket
socket_path="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

# --- Functions ---------------------------------------------------------------

get_rnote_geometry() {
    hyprctl clients | awk -v cls="$rnote_class" '
        $0 ~ "class: "cls {found=1}
        found && /at:/ {
            split($2, a, ",")
            x=a[1]; y=a[2]
        }
        found && /size:/ {
            split($2, b, "x")
            w=b[1]; h=b[2]
            print x,y,w,h
            exit
        }
    '
}

update_otd_region() {
    read x y w h <<< "$1"
    if [ -z "$x" ] || [ -z "$w" ]; then
        echo "⚠️  Rnote window not found or invalid geometry."
        return
    fi

    right=$((x + w))
    bottom=$((y + h))

    tmp=$(mktemp)
    jq --argjson l "$x" --argjson t "$y" --argjson r "$right" --argjson b "$bottom" '
      .OutputMode = "Absolute" |
      .ScreenArea.Left = $l |
      .ScreenArea.Top = $t |
      .ScreenArea.Right = $r |
      .ScreenArea.Bottom = $b
    ' "$tablet_config" > "$tmp" && mv "$tmp" "$tablet_config"

    echo "✅ Updated tablet region → X:$x Y:$y W:$w H:$h"
    systemctl --user restart opentabletdriver.service
}

monitor_events() {
    echo "📡 Listening for Rnote window changes..."
    if [ ! -S "$socket_path" ]; then
        echo "❌ Hyprland socket not found: $socket_path"
        exit 1
    fi

    socat - "UNIX-CONNECT:$socket_path" | while read -r line; do
        if echo "$line" | grep -E -q "activewindowv2>>$rnote_class|movewindow|resizewindow"; then
            geom=$(get_rnote_geometry)
            update_otd_region "$geom"
        fi
    done
}

# --- Main -------------------------------------------------------------------

geom=$(get_rnote_geometry)
if [ -n "$geom" ]; then
    update_otd_region "$geom"
else
    echo "Waiting for Rnote window to appear..."
fi

monitor_events
