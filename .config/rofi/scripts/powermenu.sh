#!/usr/bin/env bash

rofi_command="rofi -theme ~/.config/rofi/themes/sed.rasi"

uptime=$(uptime -p | sed -e 's/up //g')

# options
shutdown="shutdown"
reboot="reboot"
suspend="suspend"
logout="logout"

# variable passed to rofi
options="$lock\n$logout\n$shutdown\n$suspend\n$reboot"

chosen="$(echo -e "$options" | $rofi_command -p "神  $uptime:" -dmenu)"
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $suspend)
        # amixer set Master mute
        systemctl suspend
        ;;
    $logout)
        qtile cmd-obj -o cmd -f shutdown
        ;;
esac
