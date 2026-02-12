pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool enabled: StateService.get("caffeine.enabled", false)

    Connections {
        target: StateService
        function onStateLoaded() {
            root.enabled = StateService.get("caffeine.enabled", false);
        }
    }

    function toggle() {
        enabled = !enabled;
        StateService.set("caffeine.enabled", enabled);
    }

    function setEnabled(value: bool) {
        enabled = value;
        StateService.set("caffeine.enabled", enabled);
    }

    Process {
        id: idleInhibitProc
        command: ["systemd-inhibit", "--what=idle", "--mode=block", "--who=quickshell", "--why=Caffeine mode", "sleep", "infinity"]
        running: root.enabled
    }
}
