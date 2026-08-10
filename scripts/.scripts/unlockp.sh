#!/usr/bin/env bash
#
# unlock-android.sh — Unlock an Android device over adb using a passcode
# stored in an AES-256-CBC encrypted file (openssl, no daemon required).
#
set -euo pipefail
IFS=$'\n\t'

# ---- Config --------------------------------------------------------------
ENC_FILE="${ENC_FILE:-$HOME/.config/android-unlock/passcode.enc}"
ADB_SERIAL="${ADB_SERIAL:-}"        # set if multiple devices attached
LOCK_KEYEVENT=26                    # power button
UNLOCK_SWIPE="500 1600 500 400 300"
CONFIRM_KEYEVENT=66                 # enter/confirm

# ---- Helpers ---------------------------------------------------------
log()  { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
die()  { log "ERROR: $*"; exit 1; }

adb_cmd() {
    if [[ -n "$ADB_SERIAL" ]]; then
        adb -s "$ADB_SERIAL" "$@"
    else
        adb "$@"
    fi
}

cleanup() {
    unset pass escaped_pass PASSPHRASE 2>/dev/null || true
}
trap cleanup EXIT

# ---- Preconditions ---------------------------------------------------
command -v adb >/dev/null 2>&1 || die "adb not found in PATH"
command -v openssl >/dev/null 2>&1 || die "openssl not found in PATH"
[[ -f "$ENC_FILE" ]] || die "Encrypted passcode file not found at: $ENC_FILE"

perm=$(stat -c '%a' "$ENC_FILE" 2>/dev/null || stat -f '%Lp' "$ENC_FILE" 2>/dev/null || echo "")
if [[ -n "$perm" && "$perm" != "600" ]]; then
    log "WARNING: $ENC_FILE has permissions $perm — recommend: chmod 600 $ENC_FILE"
fi

# ---- Wait for device ---------------------------------------------------
log "Waiting for adb device..."
adb_cmd wait-for-device 2>/dev/null || die "No adb device detected"

state=$(adb_cmd get-state 2>/dev/null || echo "unknown")
[[ "$state" == "device" ]] || die "Device not ready (state: $state). Check USB debugging authorization."

# ---- Decrypt passcode --------------------------------------------------
log "Decrypting passcode..."
read -rsp "Enter passphrase: " PASSPHRASE
echo

if ! pass=$(openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d \
        -in "$ENC_FILE" -pass "pass:${PASSPHRASE}" 2>/tmp/ossl_err.$$); then
    err=$(cat /tmp/ossl_err.$$ 2>/dev/null || true)
    rm -f /tmp/ossl_err.$$
    die "Decryption failed: ${err:-wrong passphrase?}"
fi
rm -f /tmp/ossl_err.$$

[[ -n "$pass" ]] || die "Decrypted passcode is empty"

# ---- Escape for adb input text -----------------------------------------
if [[ "$pass" =~ [^a-zA-Z0-9\ !@#$%^*_+=./-] ]]; then
    log "WARNING: Passcode contains characters that may not transmit reliably via adb input text."
fi
escaped_pass=${pass// /%s}

# ---- Unlock sequence ---------------------------------------------------
log "Waking device..."
adb_cmd shell input keyevent "$LOCK_KEYEVENT" || die "Failed to send wake keyevent"
sleep 1

log "Swiping to reveal keypad..."
adb_cmd shell input swipe $UNLOCK_SWIPE || die "Failed to swipe"
sleep 1

log "Entering passcode..."
adb_cmd shell input text "$escaped_pass" || die "Failed to input passcode"

log "Confirming..."
adb_cmd shell input keyevent "$CONFIRM_KEYEVENT" || die "Failed to confirm"
sleep 2

# ---- Verify unlock succeeded --------------------------------------------
locked=$(adb_cmd shell dumpsys window 2>/dev/null | grep -m1 'mDreamingLockscreen\|isStatusBarKeyguard' || true)
if echo "$locked" | grep -qi 'true'; then
    log "WARNING: Device may still be locked — passcode possibly incorrect or timing off."
    exit 2
fi

log "Done — device unlocked."
