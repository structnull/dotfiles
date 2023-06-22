#!/bin/bash

if ! command -v adb &> /dev/null; then
    echo "ADB is not installed. Please install ADB and try again."
    exit 1
fi

device=$(adb devices | awk 'NR==2 {print $1}')
if [ -z "$device" ]; then
    echo "No device found. Connect a device and try again."
    exit 1
fi

ip_address=$(adb -s $device shell ip route | awk 'NR==1 {print $9}')

if [ -z "$ip_address" ]; then
    echo "Failed to retrieve IP address. Make sure the device is connected and try again."
    exit 1
fi

adb -s $device tcpip 5555
adb -s $device connect $ip_address:5555

echo "Device connected via Wi-Fi."
