#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <STEAM_APPID>"
    exit 1
fi

GAMEID="$1"

gamescope \
  -W 1920 -H 1080 \
  -w 1920 -h 1080 \
  -f \
  --steam \
  --rt \
  --scaler fsr \
  --filter fsr \
  --fsr-sharpness 3 \
  --adaptive-sync \
  -- \
  steam -applaunch "$GAMEID"
