#!/bin/bash

# Ask GPG to decrypt passcode into a variable (password prompt appears)
pass=$(gpg --quiet --decrypt $HOME/gpg/ssed.gpg 2>/dev/null)

if [[ -z "$pass" ]]; then
    echo "Failed to decrypt passcode!"
    exit 1
fi

echo "Unlocking device..."

adb shell input keyevent 26           # Press lock/power button
sleep 1
adb shell input touchscreen swipe 930 880 930 380  # Swipe up
sleep 1
adb shell input text "$pass"          # Input passcode
adb shell input keyevent 66           # Press Enter
sleep 1
adb shell input keyevent 26           # Press lock/power button (lock again)
echo "Done!"
