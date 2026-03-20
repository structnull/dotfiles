pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    property bool overlayVisible: false

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function showOverlay() {
        overlayVisible = true;
    }

    function hideOverlay() {
        overlayVisible = false;
    }

    function executeAction(actionId: string) {
        switch (actionId) {
            case "shutdown":
                shutdownProc.running = true;
                break;
            case "reboot":
                rebootProc.running = true;
                break;
            case "suspend":
                suspendProc.running = true;
                break;
            case "hibernate":
                hibernateProc.running = true;
                break;
            case "lock":
                lockProc.running = true;
                break;
            case "logout":
                logoutProc.running = true;
                break;
        }

        hideOverlay();
    }
    // ========================================================================
    // PROCESSES
    // ========================================================================

    Process {
        id: shutdownProc
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }

    Process {
        id: hibernateProc
        command: ["systemctl", "hibernate"]
    }

    Process {
        id: lockProc
        command: ["bash", "-c", "hyprlock || swaylock || loginctl lock-session"]
    }

    Process {
        id: logoutProc
        command: ["bash", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER"]
    }
}
