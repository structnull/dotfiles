#!/bin/bash 
# Dependencies: tesseract-ocr imagemagick scrot xsel/x11 wl-clipboard/wayland

SCR_IMG=`mktemp`
trap "rm $SCR_IMG*" EXIT

grim -g "$(slurp)" -o $SCR_IMG.png

mogrify -modulate 100,0 -resize 400% $SCR_IMG.png 

tesseract $SCR_IMG.png $SCR_IMG &> /dev/null
cat $SCR_IMG.txt | wl-copy 

exit