#!/bin/bash

cmd="$1"

if [ -z "$cmd" ]; then
    echo "Usage: $0 play-pause|next|previous"
    exit 1
fi

# Highest to lowest priority
playerctl --player=spotify,ncspot,mpv,cmus,vlc,firefox "$cmd"
