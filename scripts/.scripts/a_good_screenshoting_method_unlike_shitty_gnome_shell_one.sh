#!/usr/bin/env bash
gnome-screenshot -acf /tmp/test && cat /tmp/test | wl-copy
