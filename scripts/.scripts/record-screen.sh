#!/bin/sh

check_device() {
    [ -e "$1" ]
}

pid=$(pgrep -f gpu-screen-recorder)
status=$?

if [ $status != 0 ]; then
    notify-send "GPU Screen Recorder" "Recording has started 🎥"

    # Choose GPU render device (optional check, can skip if gpu-screen-recorder auto-selects)
    if check_device "/dev/dri/renderD128"; then
        device="/dev/dri/renderD128"
    elif check_device "/dev/dri/renderD129"; then
        device="/dev/dri/renderD129"
    else
        notify-send "GPU Screen Recorder" "No valid /dev/dri/renderD* device found ❌"
        exit 1
    fi

    # Directory setup
    output_dir="$(xdg-user-dir VIDEOS)/Screencasts"
    mkdir -p "$output_dir"

    # Start recording (fullscreen, 60 FPS, with default output audio)
    gpu-screen-recorder \
        -w screen \
        -f 60 \
        -a default_output \
        -k auto \
        -bm qp \
        -q very_high \
        -tune quality \
        -encoder gpu \
        -o "$output_dir/screencast-$(date +'%d-%m-%Y-%H%M%S').mp4" \
        >/dev/null 2>&1 &

else
    # Stop recording (SIGINT saves and exits)
    pkill -SIGINT -f gpu-screen-recorder
    notify-send "GPU Screen Recorder" "Recording has stopped 💾"
fi
