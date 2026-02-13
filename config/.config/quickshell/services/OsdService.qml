pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    property bool visible: false
    property string type: "volume" // "volume", "brightness"
    property real value: 0
    property bool muted: false
    property int serial: 0
    property real anchorX: -1
    property real anchorY: -1
    property bool suppressed: false

    // ========================================================================
    // HIDE TIMER
    // ========================================================================

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function showVolume(vol: real, isMuted: bool) {
        if (suppressed)
            return;
        root.type = "volume";
        root.value = Math.max(0, Math.min(1.5, vol));
        root.muted = isMuted;
        root.serial += 1;
        root.visible = true;
        hideTimer.restart();
    }

    function showBrightness(brightness: real) {
        if (suppressed)
            return;
        root.type = "brightness";
        root.value = Math.max(0.05, Math.min(1, brightness));
        root.muted = false;
        root.serial += 1;
        root.visible = true;
        hideTimer.restart();
    }

    onSuppressedChanged: {
        if (suppressed)
            root.visible = false;
    }

    function hide() {
        root.visible = false;
    }
}
