pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var supportedLayouts: ["scrolling", "dwindle", "master", "monocle"]
    property string currentLayout: ""
    property bool visible: false

    function show(layout: string) {
        if (!supportedLayouts.includes(layout))
            return;

        currentLayout = layout;
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1250
        onTriggered: root.visible = false
    }
}
