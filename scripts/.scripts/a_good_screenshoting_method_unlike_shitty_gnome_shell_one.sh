#!/bin/sh
gnome-screenshot -acf /tmp/test && cat /tmp/test | wl-copy
