#!/bin/sh
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-wlr
killall xdg-desktop-portal
killall xdg-desktop-portal-kde
/usr/lib/xdg-desktop-portal-hyprland &
sleep 3
/usr/lib/xdg-desktop-portal &
