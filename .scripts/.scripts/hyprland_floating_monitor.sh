#!/usr/bin/env bash

is_floating=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$is_floating" == "1" ]; then
    hyprctl dispatch togglefloating yolo
    hyprctl keyword decoration:rounding $(grep rounding ~/.config/hypr/hyprland.conf | cut -d '=' -f2)
    hyprctl keyword decoration:active_opacity $(grep active_opacity ~/.config/hypr/hyprland.conf | cut -d '=' -f2)
else
    hyprctl dispatch togglefloating yolo
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:active_opacity 1.0

    width=$(hyprctl monitors -j | jq -r 'map(.x+.width) | max')
    height=$(hyprctl monitors -j | jq -r 'map(.y+.height) | max')

    hyprctl dispatch moveactive "exact 0 0"
    hyprctl dispatch resizeactive "exact $width $height"
fi