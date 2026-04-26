pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

PanelWindow {
    id: root

    property int popupWidth: 380
    property int popupMaxHeight: 700
    property Item anchorItem: null
    property string anchorSide: "left"
    property real contentImplicitHeight: 0
    property real resolvedLeftMargin: 10
    property real resolvedTopMargin: Config.barHeight + 10

    default property alias content: contentContainer.data

    signal closing

    readonly property int screenMargin: 5

    WlrLayershell.namespace: "qs_modules"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        left: true
    }

    function recalculatePosition() {
        const screenWidth = screen ? screen.width : 1920;
        const screenHeight = screen ? screen.height : 1080;
        const minPopupTop = Config.barHeight + 10;

        let centerX = 0;
        let popupTop = Config.barHeight + 10;

        if (anchorItem) {
            const centerPos = anchorItem.mapToGlobal(anchorItem.width / 2, anchorItem.height);
            const bottomPos = anchorItem.mapToGlobal(0, anchorItem.height);
            centerX = centerPos.x;
            popupTop = bottomPos.y + 8;
        } else if (anchorSide === "right") {
            centerX = screenWidth - ((popupWidth / 2) + 10);
        } else {
            centerX = (popupWidth / 2) + 10;
        }

        resolvedLeftMargin = Math.max(10, Math.min(screenWidth - popupWidth - 10, centerX - (popupWidth / 2)));
        resolvedTopMargin = Math.max(minPopupTop, Math.min(screenHeight - 10, popupTop));
    }

    margins {
        top: resolvedTopMargin
        left: resolvedLeftMargin
        right: 0
    }

    implicitWidth: popupWidth + (screenMargin * 2)
    implicitHeight: popupMaxHeight
    visible: false
    color: "transparent"

    property bool isClosing: false
    property real openProgress: 0.0

    // Content opacity derived from openProgress — content fades in after
    // container is partially visible, and fades out before container fully closes.
    readonly property real contentOpacity: Math.max(0, Math.min(1, (openProgress - 0.15) / 0.65))

    function closeWindow() {
        if (!visible || isClosing)
            return;
        isClosing = true;
        openAnimation.stop();
        closeAnimation.restart();
    }

    // -- Open: smooth deceleration --
    NumberAnimation {
        id: openAnimation
        target: root
        property: "openProgress"
        from: 0
        to: 1
        duration: 380
        easing.type: Easing.OutQuart
    }

    // -- Close: natural settle-back --
    NumberAnimation {
        id: closeAnimation
        target: root
        property: "openProgress"
        to: 0
        duration: 300
        easing.type: Easing.InCubic
        onFinished: {
            if (!root.isClosing)
                return;

            root.closing();
            root.visible = false;
            root.isClosing = false;
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: false
        onCleared: root.closeWindow()
    }

    Timer {
        id: grabTimer
        interval: 10
        onTriggered: {
            focusGrab.active = true;
            background.forceActiveFocus();
        }
    }

    Timer {
        id: positionRefreshTimer
        interval: 1
        repeat: false
        onTriggered: root.recalculatePosition()
    }

    onVisibleChanged: {
        if (visible) {
            recalculatePosition();
            positionRefreshTimer.restart();
            isClosing = false;
            closeAnimation.stop();
            openProgress = 0;
            openAnimation.restart();
            grabTimer.restart();
        } else {
            focusGrab.active = false;
            openAnimation.stop();
            closeAnimation.stop();
            openProgress = 0;
            isClosing = false;
        }
    }

    onAnchorItemChanged: {
        if (visible)
            positionRefreshTimer.restart();
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: background
            width: root.popupWidth
            height: Math.min(root.popupMaxHeight, root.contentImplicitHeight + 32)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            color: Config.backgroundTransparentColor
            radius: Config.radiusLarge
            border.width: 1.0
            border.color: Qt.alpha(Config.textColor, 0.2)
            clip: true

            transformOrigin: Item.Top

            y: (1 - root.openProgress) * -16
            scale: 0.95 + (root.openProgress * 0.05)
            opacity: root.openProgress

            Behavior on height {
                enabled: root.openProgress >= 1.0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuad
                }
            }

            Keys.onEscapePressed: root.closeWindow()

            Item {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.contentOpacity
            }
        }
    }
}
