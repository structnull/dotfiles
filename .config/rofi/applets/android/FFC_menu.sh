#!/usr/bin/env bash

## Author  : Aditya Shakya
## Mail    : adi1090x@gmail.com
## Github  : @adi1090x
## Twitter : @adi1090x

dir="$HOME/.config/rofi/applets/android"
rofi_command="rofi -theme $dir/three.rasi"

# Links
en="樂"
di=""
settings=""

# Error msg
msg() {
	rofi -theme "$dir/message.rasi" -e "$1"
}

# Variable passed to rofi
options="$en\n$settings\n$di"

chosen="$(echo -e "$options" | $rofi_command -p "Most Used" -dmenu -selected-row 1)"
case $chosen in
    $en)
        /home/adharsh/.scripts/booba.sh On 
        ;;
    $settings)
        nvidia-settings
        ;;
    $di)
        /home/neville/.scripts/booba.sh Off
        ;;
esac

