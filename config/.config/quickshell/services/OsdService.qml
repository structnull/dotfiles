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
    property point anchor: Qt.point(0, 0)
    property ShellScreen anchorScreen: null
    property list<QtObject> suppressors: []
    property ShellScreen _candidateScreen: null
    property point _candidateAnchor: Qt.point(0, 0)
    readonly property bool suppressed: suppressors.some(owner => owner !== null)
    signal anchorRequested

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

    function suppress(owner: QtObject, enabled: bool) {
        if (enabled) {
            if (!suppressors.includes(owner))
                suppressors.push(owner);
        } else {
            suppressors = suppressors.filter(item => item && item !== owner);
        }
    }

    function offerAnchor(screen: ShellScreen, position: point): void {
        if (!_candidateScreen) {
            _candidateScreen = screen;
            _candidateAnchor = position;
        }
    }

    function refreshAnchor() {
        _candidateScreen = null;
        anchorRequested();
        anchor = _candidateAnchor;
        anchorScreen = _candidateScreen;
    }

    function showVolume(vol: real, isMuted: bool) {
        if (suppressed)
            return;
        refreshAnchor();
        root.type = "volume";
        root.value = Math.max(0, Math.min(1.5, vol));
        root.muted = isMuted;
        root.visible = true;
        hideTimer.restart();
    }

    function showBrightness(brightness: real) {
        if (suppressed)
            return;
        refreshAnchor();
        root.type = "brightness";
        root.value = Math.max(0.05, Math.min(1, brightness));
        root.muted = false;
        root.visible = true;
        hideTimer.restart();
    }

    onSuppressedChanged: {
        if (suppressed)
            root.visible = false;
    }
}
