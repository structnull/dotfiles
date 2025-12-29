#!/bin/bash
#
# based on this manual:
# https://grabski.me/tech,/linux/2020/09/02/automatically-unlock-keepassxc-on-startup-and-after-lock-screen/

verify_cmd_exists() {
  command -v "$@" >/dev/null 2>&1 || (echo "$@ not installed" && exit 1)
}

verify_cmd_exists secret-tool || exit 1
verify_cmd_exists gdbus || exit 1

APP_NAME="keepassxc"
SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"

add() {
  local keepass_db_path="$1"
  secret-tool store --label='KeePassXC Unlocker' service keepassxc-unlocker username "$keepass_db_path"
}

autostart-add() {
  mkdir -p "$HOME/.config/systemd/user"
  echo \
    "[Unit]
Description=keepassxc-unlocker start up

[Service]
ExecStart=$SCRIPT_DIR/keepassxc-unlocker run
Restart=on-failure

[Install]
WantedBy=graphical-session.target" >"$HOME/.config/systemd/user/keepassxc-unlocker-startup.service"
  echo \
    "[Unit]
Description=keepassxc-unlocker watch

[Service]
ExecStart=$SCRIPT_DIR/keepassxc-unlocker watch
Restart=on-failure

[Install]
WantedBy=graphical-session.target" >"$HOME/.config/systemd/user/keepassxc-unlocker-watch.service"

  systemctl --user daemon-reload
  systemctl --user enable --now keepassxc-unlocker-startup.service
  systemctl --user enable --now keepassxc-unlocker-watch.service
}

autostart-remove() {
  systemctl --user disable --now keepassxc-unlocker-startup.service
  systemctl --user disable --now keepassxc-unlocker-watch.service
  rm -f "$HOME/.config/systemd/user/keepassxc-unlocker-startup.service"
  rm -f "$HOME/.config/systemd/user/keepassxc-unlocker-watch.service"
  systemctl --user daemon-reload
}

run() {
  prev_pid=""
  while true; do
    current_pid=$(pgrep -xo "$APP_NAME")
    if [ -n "$current_pid" ] && [ "$current_pid" != "$prev_pid" ]; then
      echo "$APP_NAME has started or changed its PID to $current_pid."
      if unlock; then
        prev_pid=$current_pid
      fi
    fi
    sleep 5
  done
}

unlock() {
  readarray -t secret_to_db_path_arr < <(secret-tool search --all service keepassxc-unlocker 2>&1 |
    awk '/^secret|^attribute.username/ {print $3}')

  for ((i = 0; i < ${#secret_to_db_path_arr[@]}; i = $((i + 2)))); do
    password=${secret_to_db_path_arr[$i]}
    database=${secret_to_db_path_arr[$i + 1]}

    gdbus call --session \
      --dest=org.keepassxc.KeePassXC.MainWindow \
      --object-path /keepassxc \
      --method org.keepassxc.KeePassXC.MainWindow.openDatabase "$database" "$(printf '%q' "$password")"
  done
}

watch() {
  # from here:
  # https://github.com/keepassxreboot/keepassxc/blob/develop/src/gui/osutils/nixutils/ScreenLockListenerDBus.cpp

  trap 'kill 0' EXIT # killing children in case of parent's death

  unlock_on_status() {
    while read; do
      STATUS=$(echo "$REPLY" | sed -n 's/.*uint32 \(\(true\|false\|[0-9]\+\)\).*/\1/p')
      if [[ "$STATUS" == "$1" ]]; then
        unlock
      fi
    done
  }

  gdbus monitor --session \
    --dest org.gnome.ScreenSaver \
    --object-path /org/gnome/ScreenSaver |
    grep ActiveChanged |
    unlock_on_status false &
  gdbus monitor --session \
    --dest org.freedesktop.ScreenSaver \
    --object-path /org/freedesktop/ScreenSaver |
    grep ActiveChanged |
    unlock_on_status false &
  gdbus monitor --session \
    --dest org.xfce.ScreenSaver \
    --object-path /org/xfce/ScreenSaver |
    grep ActiveChanged |
    unlock_on_status false &
  gdbus monitor --session \
    --dest org.gnome.SessionManager \
    --object-path /org/gnome/SessionManager/Presence |
    grep --line-buffered StatusChanged |
    unlock_on_status 0 &

  wait
}

case "$1" in
add)
  add "${@:2}"
  ;;
autostart)
  case "$2" in
  add)
    autostart-add
    ;;
  remove)
    autostart-remove
    ;;
  esac
  ;;
run)
  run "${@:2}"
  ;;
unlock)
  unlock "${@:2}"
  ;;
watch)
  watch "${@:2}"
  ;;
*)
  echo "Add KDBX unlock password to keyring:"
  echo "   keepassxc-unlocker add <kdbx file path>"
  echo "Add unlocker to autostart:"
  echo "   keepassxc-unlocker autostart add"
  echo "Remove unlocker from autostart:"
  echo "   keepassxc-unlocker autostart remove"
  echo "Unlock all kdbx databases keyring has passwords for:"
  echo "   keepassxc-unlocker unlock"
  echo "Run session unlock watcher:"
  echo "   keepassxc-unlocker watch"
  ;;
esac
