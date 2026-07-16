#!/usr/bin/env bash

cliphist list | rofi -dmenu -theme ~/.config/rofi/clip.rasi | cliphist decode | wl-copy
