#!/bin/sh
swayidle -w \
                timeout 120 'temp=$(brightnessctl g); brightnessctl set $((temp / 4))' \
                    resume 'temp=$(brightnessctl g); brightnessctl set $((temp * 4))' \
                timeout 300 "$HOME/.scripts/lock.sh & sleep 1 && hyprctl dispatch dpms off" \
                    resume 'hyprctl dispatch dpms on' \
                ##timeout 600 'systemctl suspend'