#!/usr/bin/env bash

check_device() {
    [ -e "$1" ]
}

if ! pgrep -f '[g]pu-screen-recorder' >/dev/null; then
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
    output_dir="$HOME/Videos/Screencasts"
    mkdir -p "$output_dir" || {
        notify-send "GPU Screen Recorder" "Could not create $output_dir ❌"
        exit 1
    }
    output_file="$output_dir/screencast-$(date +'%d-%m-%Y-%H%M%S').mp4"

    # Start recording (fullscreen, 60 FPS, with default output audio)
    gpu-screen-recorder \
        -w screen \
        -f 60 \
        -a default_output \
        -k h264 \
        -bm qp \
        -q very_high \
        -tune quality \
        -encoder gpu \
        -o "$output_file" \
        >/dev/null 2>&1 &

    recorder_pid=$!
    sleep 1
    if kill -0 "$recorder_pid" 2>/dev/null; then
        notify-send "GPU Screen Recorder" "Recording to $output_file 🎥"
    else
        notify-send "GPU Screen Recorder" "Recording failed to start ❌"
        exit 1
    fi

else
    # Stop recording (SIGINT saves and exits)
    pkill -SIGINT -f '[g]pu-screen-recorder'
    if [ $? -eq 0 ]; then
        for _ in {1..30}; do
            pgrep -f '[g]pu-screen-recorder' >/dev/null || break
            sleep 1
        done
        if pgrep -f '[g]pu-screen-recorder' >/dev/null; then
            notify-send "GPU Screen Recorder" "Recording is still saving ⚠️"
        else
            notify-send "GPU Screen Recorder" "Recording saved in $HOME/Videos/Screencasts 💾"
        fi
    else
        notify-send "GPU Screen Recorder" "Could not stop recording ❌"
        exit 1
    fi
fi
