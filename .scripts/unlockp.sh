#!/bin/bash
set -e

DB="$HOME/keys/keepass/ssed.kdbx"
ENTRY="android-phone"

# Retrieve password (non-interactive)
pass=$(keepassxc-cli show "$DB" "$ENTRY" -s -a Password)

if [[ -z "$pass" ]]; then
    echo "❌ Failed to retrieve passcode (is KeePassXC unlocked?)"
    exit 1
fi

# Escape spaces for adb
escaped_pass=$(printf '%s' "$pass" | sed 's/ /%s/g')

echo "🔓 Unlocking device..."

adb shell input keyevent 26
sleep 1
adb shell input swipe 500 1600 500 400 300
sleep 1
adb shell input text "$escaped_pass"
adb shell input keyevent 66
sleep 2
adb shell input keyevent 26

echo "✅ Done!"
