#!/usr/bin/env bash

GAMEMODE_STATE=$(hyprctl -j getoption animations:enabled | jq '.bool')

if [ "$GAMEMODE_STATE" = "true" ]; then
    hyprctl eval '
        hl.config({
            animations = { enabled = false },
            decoration = {
                shadow = { enabled = false },
                blur = {
                    enabled = false,
                    ignore_opacity = false,
                },
                rounding = 0,
            },
            general = {
                border_size = 1,
            },
        })
        hl.monitor({
            output = "",
            mode = "1920x1080@60.00",
            position = "auto",
            scale = 1,
        })
    '
    exit
fi

hyprctl reload
