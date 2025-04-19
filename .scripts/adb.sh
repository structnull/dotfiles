#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if ADB is installed
if ! command_exists adb; then
    echo "ADB is not installed or not in your PATH. Please install ADB and ensure it's accessible."
    exit 1
fi

# Get the list of devices connected via USB
usb_devices=$(adb devices | awk '$2 == "device" && $1 !~ /:5555$/ {print $1}')

# Get the list of devices connected via Wi-Fi
wifi_devices=$(adb devices | awk '$2 == "device" && $1 ~ /:5555$/ {print $1}')

# Check if any USB-connected devices are present
if [ -z "$usb_devices" ]; then
    echo "No USB-connected devices found. Please connect a device via USB and try again."
    exit 1
fi

# Process each USB-connected device
for device in $usb_devices; do
    echo "Processing device: $device"

    # Retrieve the device's IP address
    ip_address=$(adb -s "$device" shell ip -f inet addr show wlan0 | awk '/inet / {print $2}' | cut -d/ -f1)

    if [ -z "$ip_address" ]; then
        echo "Failed to retrieve IP address for device $device. Ensure the device is connected to Wi-Fi."
        continue
    fi

    echo "Device IP address: $ip_address"

    # Check if the device is already connected via Wi-Fi
    if echo "$wifi_devices" | grep -q "$ip_address:5555"; then
        echo "Device $device is already connected via Wi-Fi."
        continue
    fi

    # Restart ADB daemon to listen on TCP/IP
    adb -s "$device" tcpip 5555
    if [ $? -ne 0 ]; then
        echo "Failed to set device $device to TCP/IP mode."
        continue
    fi

    # Wait to ensure the device is ready
    sleep 2

    # Connect to the device over Wi-Fi
    adb connect "$ip_address:5555"
    if [ $? -eq 0 ]; then
        echo "Successfully connected to $device at $ip_address over Wi-Fi."
    else
        echo "Failed to connect to $device at $ip_address over Wi-Fi."
    fi
done
