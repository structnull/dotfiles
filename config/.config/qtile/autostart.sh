#!/bin/sh
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
nitrogen --restore &
picom --experimental-backends &
dunst &
xbindkeys &
numlockx &
nm-applet &
