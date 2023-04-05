#!/bin/sh
#
HYPRPERFMODE=$(hyprctl getoption animations:enabled | sed -n '2p' | awk '{print $2}')
if [ $HYPRPERFMODE = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0;\
        keyword monitor eDP-1,1920x1080@60,0x0,1"
    exit
fi
hyprctl reload
