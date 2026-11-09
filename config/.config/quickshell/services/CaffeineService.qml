pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
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

}
