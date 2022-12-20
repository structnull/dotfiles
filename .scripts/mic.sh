#!/bin/sh
# script used to toggle between two conditions

TOGGLE=/tmp/.toggle_Mic

if [ ! -e $TOGGLE ]; then
    touch $TOGGLE
	pactl set-source-mute @DEFAULT_SOURCE@ on
    notify-send "Internal Microphone Muted"
else
    rm $TOGGLE
	pactl set-source-mute @DEFAULT_SOURCE@ off
    notify-send "Internal Microphone Unmuted"
fi
