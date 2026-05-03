#!/bin/bash 

SCR_IMG=$(mktemp)
trap 'rm -f "$SCR_IMG"*' EXIT

grim -l 9 -g "$(slurp)" "$SCR_IMG.png"

wl-copy < "$SCR_IMG.png"

exit
