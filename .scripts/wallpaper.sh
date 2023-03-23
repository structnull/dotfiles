#!/bin/bash

# Set the path to your wallpaper directory here:
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Get a list of all the images in the wallpaper directory:
WALLPAPERS=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.png")

# Use rofi to display a list of wallpapers and allow the user to select one:
SELECTED=$(echo "$WALLPAPERS" | rofi -dmenu -i -p "Select Wallpaper" -no-custom -fullscreen)

# Escape any special characters in the paths:
SELECTED_ESCAPED=$(echo "$SELECTED" | sed 's/[\/&]/\\&/g')
WALLPAPER_DIR_ESCAPED=$(echo "$WALLPAPER_DIR" | sed 's/[\/&]/\\&/g')

# Use sed to replace the wallpaper path in the configuration file:
sed -i "s|$WALLPAPER_DIR_ESCAPED/.*$|$SELECTED_ESCAPED|g" "$HOME/.config/hypr/hyprland.conf"

echo $WALLPAPER_DIR_ESCAPED
if [[ $(pidof swaybg) ]]; then
  pkill swaybg
fi
# Use swaybg to set the selected wallpaper as the background:
swaybg -i "$SELECTED" &

# Wait for a moment to ensure the wallpaper has been set:
sleep 1s
