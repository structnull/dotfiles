#!/bin/bash

gfx_mode=$(supergfxctl -g)

if [ "$gfx_mode" = "Hybrid" ]; then
    notify-send -u critical "Error" "Switch to integrated first!!"
else
    sh -c "virsh --connect=qemu:///system start win10; sleep 13; looking-glass-client -F"
fi
