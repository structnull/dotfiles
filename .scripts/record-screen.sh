#!/bin/sh

pid=`pgrep wf-recorder`
status=$?

if [ $status != 0 ]; then
     notify-send "Recording has started";
	 wf-recorder --audio=alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c h264_vaapi -d /dev/dri/renderD129 -f $(xdg-user-dir VIDEOS)/Screencasts/screencast-$(date +'%Y-%m-%d-%H%M%S.mp4');

else
	 pkill --signal SIGINT wf-recorder
     notify-send "Recording has stopped";
fi;

