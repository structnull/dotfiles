#!/usr/bin/env bash

# You can call this script like this:
# $ ./brightnessControl.sh up
# $ ./brightnessControl.sh down

# Script inspired by these wonderful people:
# https://github.com/dastorm/volume-notification-dunst/blob/master/volume.sh
# https://gist.github.com/sebastiencs/5d7227f388d93374cebdf72e783fbd6a

NotificationID_File=/tmp/brightness_notification_id

function get_brightness {
	brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}'
}

function get_notification_id {
  if [ -s "$NotificationID_File" ]; then
    cat $NotificationID_File
  else
    echo 0
  fi
}

case $1 in
  up)
    # increase the backlight by 5%
    brightnessctl set 5%+
    ;;
  down)
    # decrease the backlight by 5%
    brightnessctl set 5%-
    ;;
  max)
    brightnessctl set 100%
    ;;
  blank)
    brightnessctl set 0%
    ;;
esac
