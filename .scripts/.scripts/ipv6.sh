#!/bin/sh

# Check if IPv6 is currently enabled or disabled
ipv6_status=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)

# Toggle the IPv6 status
if [ "$ipv6_status" -eq "0" ]; then
    sudo bash -c "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
    notify-send "IPv6 disabled"
else
    sudo bash -c "echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6"
    notify-send "IPv6 enabled"
fi
