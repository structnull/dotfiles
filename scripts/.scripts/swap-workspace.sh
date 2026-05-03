#!/bin/sh

WORKSPACE="$1"

monitors_out="$(hyprctl monitors -j)"
focused_mon="$(echo "$monitors_out" | jq '.[] | select(.focused==true) | .id')"
focused_wks="$(echo "$monitors_out" | jq '.[].activeWorkspace.id')"

# Workspace is already focused, check on which monitor
if echo "$focused_wks" | grep "$WORKSPACE" >/dev/null; then
    mon_id="$(echo "$monitors_out" | jq ".[] | select(.activeWorkspace.id==$WORKSPACE) | .id")"

  # If the workspace is focused on the active monitor, don't do anything (we're here).
  # Otherwise, swap the workspaces.
  if [ "$mon_id" -ne "$focused_mon" ]; then
      hyprctl dispatch swapactiveworkspaces "$focused_mon" "$mon_id"
  fi
  # Switching to an unfocused workspace, always move it to focused monitor
else
    hyprctl dispatch moveworkspacetomonitor "$WORKSPACE" "$focused_mon"
    hyprctl dispatch workspace "$WORKSPACE"
fi
