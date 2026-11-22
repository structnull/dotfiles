pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool overlayVisible: false
    property bool overlayLoaded: false
    property string error: ""

    function showOverlay() {
        closeDelay.stop();
        error = "";
        overlayVisible = true;
        overlayLoaded = true;
    }

    function hideOverlay() {
        if (!overlayVisible)
            return;
        overlayVisible = false;
        closeDelay.restart();
    }

    function executeAction(actionId: string) {
        if (actionProcess.running)
            return;
        error = "";
        switch (actionId) {
        case "shutdown":
            actionProcess.exec(["systemctl", "poweroff"]);
            break;
        case "reboot":
        case "suspend":
        case "hibernate":
            actionProcess.exec(["systemctl", actionId]);
            break;
        case "lock":
            Quickshell.execDetached(["sh", "-c",
                "if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ] && command -v hyprlock >/dev/null; then exec hyprlock; fi; if command -v swaylock >/dev/null; then exec swaylock; fi; exec loginctl lock-session"]);
            hideOverlay();
            break;
        case "logout":
            actionProcess.exec(["sh", "-c",
                "if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ] && command -v hyprshutdown >/dev/null; then exec hyprshutdown; fi; if [ -n \"$XDG_SESSION_ID\" ]; then exec loginctl terminate-session \"$XDG_SESSION_ID\"; fi; echo 'No graphical session ID is available.' >&2; exit 1"]);
            break;
        }
    }

    Timer {
        id: closeDelay
        interval: 350
        onTriggered: root.overlayLoaded = false
    }

    Process {
        id: actionProcess
        stderr: StdioCollector { id: errorOutput }
        onExited: (code, status) => {
            if (code === 0 && status === 0) {
                root.hideOverlay();
            } else {
                root.error = errorOutput.text.trim() || "The power action failed.";
                console.warn("[PowerService]", root.error);
            }
        }
    }
}
