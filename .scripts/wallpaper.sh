#!/bin/bash

# Set the path to your wallpaper directory here:
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Get the current wallpaper path from the configuration file:
WALLPAPER_CONF="$HOME/.config/hypr/wallpaper.conf"
CURRENT_WALLPAPER=$(grep -o '$wall=".*"' "$WALLPAPER_CONF" | cut -d '"' -f 2)

# Check if the wallpaper path is empty:
if [ -z "$CURRENT_WALLPAPER" ]; then
  # Get a list of all the images in the wallpaper directory:
  WALLPAPERS=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.png")

  # Use rofi to display a list of wallpapers and allow the user to select one:
  SELECTED=$(echo "$WALLPAPERS" | rofi -dmenu -i -p "Select Wallpaper" -theme ~/.config/rofi/wall.rasi)

  if [ -z "$SELECTED" ]; then
    exit 0
  fi

  # Escape any special characters in the paths:
  SELECTED_ESCAPED=$(echo "$SELECTED" | sed 's/[\/&]/\\&/g')
  WALLPAPER_DIR_ESCAPED=$(echo "$WALLPAPER_DIR" | sed 's/[\/&]/\\&/g')

  # Use sed to replace the wallpaper path in the configuration file:
  sed -i "s|\$wall=\".*\"|\$wall=\"$SELECTED_ESCAPED\"|g" "$WALLPAPER_CONF"

  CURRENT_WALLPAPER="$SELECTED"
else
  # Use sed to replace the wallpaper path in the configuration file:
  sed -i "s|\$wall=\".*\"|\$wall=\"\"|g" "$WALLPAPER_CONF"
fi

# Kill any existing swaybg process:
killall swaybg &>/dev/null

# Use swaybg to set the selected wallpaper as the background:
swaybg -i "$CURRENT_WALLPAPER" &

# Wait for a moment to ensure the wallpaper has been set:
sleep 1s
