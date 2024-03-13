#!/bin/bash 
# Dependencies: tesseract-ocr imagemagick scrot xsel/x11 wl-clipboard/wayland

SCR_IMG=$(mktemp)
trap 'rm -f "$SCR_IMG"*' EXIT

# Capture screenshot with grim, increase image quality with option -q from default 75 to 100
grim -l 9 -g "$(slurp)" "$SCR_IMG.png"

# Enhance the image quality before OCR
mogrify -modulate 100,0 -resize 400% "$SCR_IMG.png"

# Use Tesseract to perform OCR on the screenshot, discard stderr
tesseract "$SCR_IMG.png" "$SCR_IMG" 2>/dev/null

wl-copy < "$SCR_IMG.txt"

exit
