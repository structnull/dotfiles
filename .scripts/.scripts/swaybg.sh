#!/bin/sh
wallpaper_directory=$1
duration=$2

[ -z "$wallpaper_directory" ] && echo "Usage: $(basename $0) ~/Pictures/wallpapers 30 minutes" && exit 1
[ ! -d "$wallpaper_directory" ] && echo "Directory \'$wallpaper_directory\' does not exist" && exit 1
[ -z "$duration" ] && duration=30

while true; do
    for file in $(ls "$wallpaper_directory"); do
        current_swaybg_pid=$(pgrep -x swaybg)
        wallpaper="$wallpaper_directory/$file"
        format=$(file "$wallpaper" | cut -d " " -f 2)
        [ "$format" = "JPEG" ] || [ "$format" = "JP G" ] || [ "$format" = "PNG" ] \
            && echo "Setting wallpaper $wallpaper, format $format, sleeping $duration." \
            && sh -c "swaybg -o \"*\" -i $wallpaper -m fill -c \"#000000\" > /dev/null 2>&1 &" \
            && sleep 0.5 \
            && kill $current_swaybg_pid
        sleep $duration
    done
done