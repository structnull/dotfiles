#!/bin/sh

check_device() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

pid=$(pgrep wf-recorder)
status=$?

if [ $status != 0 ]; then
    notify-send "Recording has started";

    # Check if /dev/dri/renderD128 exists
    if check_device "/dev/dri/renderD128" && wf-recorder --audio=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c h264_vaapi -d /dev/dri/renderD128 -f "$(xdg-user-dir VIDEOS)/Screencasts/screencast-$(date +'%d-%m-%Y-%H%M%S.mp4')" 2>/dev/null; then
        device="/dev/dri/renderD128"
    elif check_device "/dev/dri/renderD129"; then
        device="/dev/dri/renderD129"
    else
        echo "Neither /dev/dri/renderD128 nor /dev/dri/renderD129 is available or there was an error with both devices."
        exit 1
    fi

    wf-recorder --audio=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c h264_vaapi -d "$device" -f "$(xdg-user-dir VIDEOS)/Screencasts/screencast-$(date +'%d-%m-%Y-%H%M%S.mp4')";

else
    pkill --signal SIGINT wf-recorder
    notify-send "Recording has stopped";
fi;
