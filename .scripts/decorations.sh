#!/bin/sh

TOGGLE=/tmp/.toggle_anim

if [ ! -e $TOGGLE ]; then
    touch $TOGGLE
    hyprctl keyword animations:enabled 0  
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:blur 0
    notify-send "Decorations Disabled"
else
    rm $TOGGLE
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:rounding 10
    hyprctl keyword decoration:blur 1
    notify-send "Decorations Enabled"
fi
