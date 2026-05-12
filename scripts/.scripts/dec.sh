#!/usr/bin/env sh
HYPRGAMEMODE=$(hyprctl getoption animations.enabled | awk 'NR==1{print $NF}')
case "$HYPRGAMEMODE" in
1|true|yes|on)
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = {
            shadow = { enabled = false },
            blur = {
                enabled = false,
                ignore_opacity = false,
            },
            rounding = 0,
        },
        general = { border_size = 1 },
    })'
    exit
    ;;
esac
hyprctl reload
